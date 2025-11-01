from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RegisterView, LoginView, PatientViewSet, DoctorViewSet, PreTriageViewSet

router = DefaultRouter()
router.register(r'patients', PatientViewSet)
router.register(r'doctors', DoctorViewSet)
router.register(r'pre-triage', PreTriageViewSet)

urlpatterns = [
    path('auth/register', RegisterView.as_view(), name='auth-register'),
    path('auth/login', LoginView.as_view(), name='auth-login'),
    path('', include(router.urls)),
]
