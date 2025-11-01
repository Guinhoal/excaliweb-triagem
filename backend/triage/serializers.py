from rest_framework import serializers
from .models import (
    User, Patient, PatientDetails, Doctor,
    PreTriage, TriageMessage, TriageReview,
    TriageHistory, Notification, Metric, TriageAnalysis
)
from django.contrib.auth.password_validation import validate_password


class UserSerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ("id", "username", "email", "name", "role")

    def get_name(self, obj):
        if obj.first_name and obj.last_name:
            return f"{obj.first_name} {obj.last_name}"
        return obj.first_name or obj.username or obj.email


class RegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=200)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    role = serializers.ChoiceField(choices=["patient", "doctor"], default="patient")
    cpf = serializers.CharField(max_length=15, required=False)
    crm = serializers.CharField(max_length=15, required=False)
    phone_number = serializers.CharField(max_length=20, required=False, allow_null=True, allow_blank=True)

    def validate_password(self, value):
        validate_password(value)
        return value

    def validate(self, attrs):
        # Normalizações básicas
        attrs = super().validate(attrs)
        name = (attrs.get("name") or "").strip()
        email = (attrs.get("email") or "").strip().lower()
        role = attrs.get("role") or "patient"
        cpf = (attrs.get("cpf") or "").strip() or None
        crm = (attrs.get("crm") or "").strip() or None

        if not name:
            raise serializers.ValidationError({"name": "Nome é obrigatório."})
        if not email:
            raise serializers.ValidationError({"email": "Email é obrigatório."})

        # Evitar duplicidade de usuário
        if User.objects.filter(username=email).exists():
            raise serializers.ValidationError({"email": "Já existe um usuário com este email."})

        # Regras específicas por perfil
        if role == "doctor":
            if not crm:
                raise serializers.ValidationError({"crm": "CRM é obrigatório para médicos."})
            if Doctor.objects.filter(crm=crm).exists():
                raise serializers.ValidationError({"crm": "CRM já cadastrado."})
            if cpf and Doctor.objects.filter(cpf=cpf).exists():
                raise serializers.ValidationError({"cpf": "CPF já cadastrado para um médico."})
        else:
            # Paciente
            if cpf and Patient.objects.filter(cpf=cpf).exists():
                raise serializers.ValidationError({"cpf": "CPF já cadastrado para um paciente."})

        # Atribuir de volta (normalizados)
        attrs["name"] = name
        attrs["email"] = email
        attrs["cpf"] = cpf
        attrs["crm"] = crm
        return attrs

    def create(self, validated_data):
        import logging
        logger = logging.getLogger(__name__)
        
        role = validated_data.get("role", "patient")
        name = validated_data["name"].strip()
        email = validated_data["email"].strip().lower()
        password = validated_data["password"]
        cpf = validated_data.get("cpf")
        crm = validated_data.get("crm")
        phone_number = validated_data.get("phone_number")

        logger.info(f"Creating user with role={role}, email={email}, cpf={cpf}, crm={crm}")

        username = email
        try:
            user = User.objects.create_user(
                username=username,
                email=email,
                password=password,
                first_name=name,
                role=role,
            )
            logger.info(f"User created with id={user.id}")
        except Exception as e:
            logger.error(f"Error creating user: {e}")
            raise

        try:
            if role == "patient":
                # CPF é obrigatório no modelo, mas permitimos gerar um temporário
                patient_cpf = cpf if cpf else f"CPF-{user.id}-{email[:5]}"
                logger.info(f"Creating patient with cpf={patient_cpf}")
                Patient.objects.create(
                    user=user, 
                    name=name, 
                    cpf=patient_cpf, 
                    email=email, 
                    phone_number=phone_number
                )
            else:
                # Para médico, CRM é obrigatório (já validado), CPF pode ser gerado
                doctor_cpf = cpf if cpf else f"CPF-{user.id}-{email[:5]}"
                logger.info(f"Creating doctor with crm={crm}, cpf={doctor_cpf}")
                Doctor.objects.create(
                    user=user, 
                    name=name, 
                    crm=crm, 
                    cpf=doctor_cpf, 
                    email=email, 
                    phone_number=phone_number
                )
            logger.info(f"Profile created successfully for user {user.id}")
        except Exception as e:
            logger.error(f"Error creating profile: {e}")
            # Se falhar ao criar o perfil, deletar o usuário para evitar inconsistências
            user.delete()
            raise
        
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Patient
        fields = "__all__"


class PatientDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = PatientDetails
        fields = ["patient_details_id", "patient", "age", "blood_type", "allergy"]
        read_only_fields = ["patient_details_id", "patient"]
        extra_kwargs = {
            'patient': {'required': False}
        }


class DoctorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Doctor
        fields = "__all__"


class PreTriageSerializer(serializers.ModelSerializer):
    # Tornar channel opcional com default 'web' e patient opcional (derivado do usuário autenticado)
    channel = serializers.ChoiceField(choices=PreTriage.CHANNEL_CHOICES, required=False, default="web")
    patient = serializers.PrimaryKeyRelatedField(queryset=Patient.objects.all(), required=False)

    class Meta:
        model = PreTriage
        fields = "__all__"
        read_only_fields = ("pre_triage_id", "ai_confidence", "risk_level", "triage_code", "status", "created_at")

    def create(self, validated_data):
        request = self.context.get("request")
        patient = validated_data.get("patient")
        if not patient and request and hasattr(request.user, "patient_profile"):
            validated_data["patient"] = request.user.patient_profile
        if not validated_data.get("channel"):
            validated_data["channel"] = "web"
        return super().create(validated_data)


class TriageMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = TriageMessage
        fields = "__all__"


class TriageReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = TriageReview
        fields = "__all__"


class TriageHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = TriageHistory
        fields = "__all__"


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = "__all__"


class MetricSerializer(serializers.ModelSerializer):
    class Meta:
        model = Metric
        fields = "__all__"


class TriageAnalysisSerializer(serializers.ModelSerializer):
    class Meta:
        model = TriageAnalysis
        fields = "__all__"
        read_only_fields = ("id", "created_at")
