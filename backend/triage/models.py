from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone


class User(AbstractUser):
    ROLE_CHOICES = (
        ("patient", "Patient"),
        ("doctor", "Doctor"),
        ("admin", "Admin"),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="patient")


class Patient(models.Model):
    patient_id = models.AutoField(primary_key=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="patient_profile")
    name = models.CharField(max_length=200)
    cpf = models.CharField(max_length=15, unique=True)
    email = models.EmailField(max_length=150, unique=True)
    phone_number = models.CharField(max_length=20, null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.name} ({self.patient_id})"


class PatientDetails(models.Model):
    patient_details_id = models.AutoField(primary_key=True)
    patient = models.OneToOneField(Patient, on_delete=models.CASCADE, related_name="details")
    age = models.SmallIntegerField(null=True, blank=True)
    blood_type = models.CharField(max_length=5, null=True, blank=True)
    allergy = models.CharField(max_length=200, null=True, blank=True)


class Doctor(models.Model):
    doctor_id = models.AutoField(primary_key=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="doctor_profile")
    name = models.CharField(max_length=200)
    crm = models.CharField(max_length=15, unique=True)
    cpf = models.CharField(max_length=15, unique=True)
    email = models.EmailField(max_length=150, unique=True)
    phone_number = models.CharField(max_length=20, null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"Dr(a). {self.name} ({self.crm})"


class PreTriage(models.Model):
    CHANNEL_CHOICES = (
        ("web", "Web"),
        ("whatsapp", "WhatsApp"),
        ("totem", "Totem"),
    )

    STATUS_CHOICES = (
        ("pendente", "Pendente"),
        ("revisao", "Revisão"),
        ("finalizado", "Finalizado"),
    )

    pre_triage_id = models.AutoField(primary_key=True)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name="pre_triages")
    channel = models.CharField(max_length=30, choices=CHANNEL_CHOICES)
    symptoms_text = models.TextField(null=True, blank=True)
    symptoms_audio = models.TextField(null=True, blank=True)
    symptoms_image = models.TextField(null=True, blank=True)
    ai_confidence = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    risk_level = models.CharField(max_length=20, null=True, blank=True)
    triage_code = models.CharField(max_length=50, null=True, blank=True)
    status = models.CharField(max_length=60, choices=STATUS_CHOICES, default="pendente")
    created_at = models.DateTimeField(default=timezone.now)


class TriageMessage(models.Model):
    SENDER_TYPE_CHOICES = (
        ("patient", "Patient"),
        ("ai", "AI"),
        ("doctor", "Doctor"),
    )

    message_id = models.AutoField(primary_key=True)
    pre_triage = models.ForeignKey(PreTriage, on_delete=models.CASCADE, related_name="messages")
    sender_type = models.CharField(max_length=20, choices=SENDER_TYPE_CHOICES)
    sender_id = models.IntegerField(null=True, blank=True)
    message_text = models.TextField(null=True, blank=True)
    message_media = models.TextField(null=True, blank=True)
    audio_transcript = models.TextField(null=True, blank=True)
    sent_at = models.DateTimeField(default=timezone.now)


class TriageReview(models.Model):
    review_id = models.AutoField(primary_key=True)
    pre_triage = models.ForeignKey(PreTriage, on_delete=models.CASCADE, related_name="reviews")
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE, related_name="reviews")
    notes = models.TextField(null=True, blank=True)
    final_risk_level = models.CharField(max_length=20, null=True, blank=True)
    reviewed_at = models.DateTimeField(default=timezone.now)


class TriageHistory(models.Model):
    history_id = models.AutoField(primary_key=True)
    pre_triage = models.ForeignKey(PreTriage, on_delete=models.CASCADE, related_name="history")
    doctor = models.ForeignKey(Doctor, null=True, blank=True, on_delete=models.SET_NULL, related_name="history")
    summary = models.TextField()
    final_risk = models.CharField(max_length=20, null=True, blank=True)
    outcome = models.CharField(max_length=100, null=True, blank=True)
    recorded_at = models.DateTimeField(default=timezone.now)


class Notification(models.Model):
    notification_id = models.AutoField(primary_key=True)
    pre_triage = models.ForeignKey(PreTriage, null=True, blank=True, on_delete=models.SET_NULL, related_name="notifications")
    doctor = models.ForeignKey(Doctor, null=True, blank=True, on_delete=models.SET_NULL, related_name="notifications")
    message = models.TextField(null=True, blank=True)
    sent_at = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=20, default="enviado")


class Metric(models.Model):
    metric_id = models.AutoField(primary_key=True)
    pre_triage = models.ForeignKey(PreTriage, null=True, blank=True, on_delete=models.SET_NULL, related_name="metrics")
    response_time = models.DurationField(null=True, blank=True)
    reliability = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

class ConversationSession(models.Model):
    SESSION_STATUS_CHOICES = (
        ("active", "Active"),
        ("closed", "Closed"),
    )

    session_id = models.AutoField(primary_key=True)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name="sessions", null=True, blank=True)
    pre_triage = models.ForeignKey(PreTriage, on_delete=models.SET_NULL, related_name="session", null=True, blank=True)
    phone_number = models.CharField(max_length=50)  # Número do WhatsApp que enviou a mensagem
    current_step = models.CharField(max_length=50, default="start")  # Ex: 'confirm_number', 'collect_symptoms', etc.
    context_data = models.JSONField(default=dict, blank=True)  # Dados temporários do fluxo
    started_at = models.DateTimeField(default=timezone.now)
    last_message_at = models.DateTimeField(default=timezone.now)
    status = models.CharField(max_length=20, choices=SESSION_STATUS_CHOICES, default="active")

    def __str__(self):
        return f"Session {self.session_id} - {self.phone_number} ({self.status})"


class TriageAnalysis(models.Model):
    """
    Armazena análises de triagem realizadas pela IA durante uma sessão de conversa.
    Cada análise contém informações sobre sintomas, níveis de risco e próximas perguntas.
    """
    id = models.AutoField(primary_key=True)
    session = models.ForeignKey(
        ConversationSession, 
        on_delete=models.CASCADE, 
        related_name="analyses",
        db_column="session_id"
    )
    analysis = models.TextField(help_text="Análise detalhada dos sintomas do paciente")
    ai_confidence = models.IntegerField(
        null=True, 
        blank=True,
        help_text="Confiança da IA na análise (0-100)"
    )
    risk_level = models.IntegerField(
        null=True, 
        blank=True,
        help_text="Nível de risco calculado (0-100)"
    )
    confidence_score = models.IntegerField(
        null=True, 
        blank=True,
        help_text="Score de confiança geral (0-100)"
    )
    next_question = models.TextField(
        null=True, 
        blank=True,
        help_text="Próxima pergunta a ser feita ao paciente"
    )
    created_at = models.DateTimeField(default=timezone.now, db_index=True)

    class Meta:
        db_table = 'triage_triageanalysis'
        ordering = ['-created_at']
        verbose_name = 'Análise de Triagem'
        verbose_name_plural = 'Análises de Triagem'

    def __str__(self):
        return f"Analysis {self.id} - Session {self.session_id} (Risk: {self.risk_level}%)"

