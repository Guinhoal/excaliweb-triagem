from django.contrib import admin
from .models import (
    User, Patient, PatientDetails, Doctor, PreTriage, 
    TriageMessage, TriageReview, TriageHistory, 
    Notification, Metric, ConversationSession, TriageAnalysis
)

@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
	list_display = ("patient_id", "name", "email", "cpf", "phone_number", "created_at")
	search_fields = ("name", "email", "cpf", "phone_number")
	list_filter = ("created_at",)

@admin.register(Doctor)
class DoctorAdmin(admin.ModelAdmin):
	list_display = ("doctor_id", "name", "crm", "email", "cpf", "phone_number", "created_at")
	search_fields = ("name", "crm", "email", "cpf", "phone_number")
	list_filter = ("created_at",)

@admin.register(TriageAnalysis)
class TriageAnalysisAdmin(admin.ModelAdmin):
	list_display = ("id", "session", "risk_level", "ai_confidence", "confidence_score", "created_at")
	list_filter = ("created_at", "risk_level", "ai_confidence")
	search_fields = ("analysis", "next_question")
	readonly_fields = ("created_at",)
	ordering = ("-created_at",)

admin.site.register(User)
admin.site.register(PatientDetails)
admin.site.register(PreTriage)
admin.site.register(TriageMessage)
admin.site.register(TriageReview)
admin.site.register(TriageHistory)
admin.site.register(Notification)
admin.site.register(Metric)
admin.site.register(ConversationSession)
