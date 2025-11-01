from datetime import timedelta
import random
import string
from django.contrib.auth import authenticate
from django.utils import timezone
from rest_framework import generics, permissions, status, viewsets
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Patient, Doctor, PreTriage, TriageMessage
from .models import PatientDetails
from .serializers import (
    RegisterSerializer, LoginSerializer, UserSerializer,
    PatientSerializer, PatientDetailsSerializer, DoctorSerializer, PreTriageSerializer,
    TriageMessageSerializer
)


def _generate_triage_code():
    return "TRI-" + "".join(random.choices(string.ascii_uppercase + string.digits, k=8))


def _infer_risk_and_confidence(symptoms_text: str | None) -> tuple[str, float]:
    if not symptoms_text:
        return ("Verde", 50.0)
    text = symptoms_text.lower()
    if any(k in text for k in ["dor no peito", "falta de ar", "desmaio", "inconsciente", "hemorragia"]):
        return ("Vermelho", 92.0)
    if any(k in text for k in ["febre alta", "forte", "muito"]):
        return ("Laranja", 80.0)
    if any(k in text for k in ["febre", "dor moderada", "tontura"]):
        return ("Amarelo", 70.0)
    return ("Verde", 65.0)


class RegisterView(generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            user = serializer.save()
        except Exception as e:
            # Sanitizar erros de integridade em 400 em vez de 500
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        refresh = RefreshToken.for_user(user)
        data = {
            "token": str(refresh.access_token),
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user": UserSerializer(user).data,
        }
        return Response(data, status=status.HTTP_201_CREATED)


class LoginView(generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = LoginSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = (serializer.validated_data["email"] or "").strip().lower()
        password = serializer.validated_data["password"]
        user = authenticate(username=email, password=password)
        if not user:
            return Response({"detail": "Credenciais inválidas"}, status=status.HTTP_401_UNAUTHORIZED)
        refresh = RefreshToken.for_user(user)
        data = {
            "token": str(refresh.access_token),
            "access": str(refresh.access_token),
            "refresh": str(refresh),
            "user": UserSerializer(user).data,
        }
        return Response(data)


class PatientViewSet(viewsets.ModelViewSet):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=["get"], url_path="me")
    def me(self, request):
        if not hasattr(request.user, "patient_profile"):
            return Response({"detail": "Não é paciente"}, status=status.HTTP_403_FORBIDDEN)
        return Response(PatientSerializer(request.user.patient_profile).data)

    @action(detail=False, methods=["get", "post", "put"], url_path="me/details")
    def my_details(self, request):
        if not hasattr(request.user, "patient_profile"):
            return Response({"detail": "Não é paciente"}, status=status.HTTP_403_FORBIDDEN)
        patient = request.user.patient_profile
        try:
            details = patient.details
        except PatientDetails.DoesNotExist:
            details = None

        if request.method.lower() == "get":
            if not details:
                return Response({}, status=status.HTTP_204_NO_CONTENT)
            return Response(PatientDetailsSerializer(details).data)

        # Para POST/PUT, não incluir patient no payload pois será definido no save
        if details:
            # Atualizar detalhes existentes
            serializer = PatientDetailsSerializer(details, data=request.data, partial=True)
        else:
            # Criar novos detalhes
            serializer = PatientDetailsSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        # Garantir que o patient está associado corretamente
        instance = serializer.save(patient=patient)
        return Response(PatientDetailsSerializer(instance).data)


class DoctorViewSet(viewsets.ModelViewSet):
    queryset = Doctor.objects.all()
    serializer_class = DoctorSerializer
    permission_classes = [permissions.IsAuthenticated]


class PreTriageViewSet(viewsets.ModelViewSet):
    queryset = PreTriage.objects.all().order_by("-created_at")
    serializer_class = PreTriageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        data = serializer.validated_data
        patient = data.get('patient')
        if not patient and hasattr(self.request.user, 'patient_profile'):
            patient = self.request.user.patient_profile
        instance = serializer.save(patient=patient or serializer.validated_data.get('patient'))
        risk, conf = _infer_risk_and_confidence(instance.symptoms_text)
        instance.risk_level = risk
        instance.ai_confidence = conf
        instance.triage_code = _generate_triage_code()
        # Decide status: low risk auto finalize, medium -> revisão, high -> revisão imediata
        if risk in ("Vermelho", "Laranja"):
            instance.status = "revisao"
        else:
            instance.status = "finalizado"
        instance.save()

    @action(detail=True, methods=["post"])
    def message(self, request, pk=None):
        pre = self.get_object()
        data = request.data.copy()
        data["pre_triage"] = pre.pre_triage_id
        serializer = TriageMessageSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)

