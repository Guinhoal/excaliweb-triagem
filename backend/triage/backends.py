"""
Backend de autenticação customizado para permitir login por email
"""
from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend

User = get_user_model()


class EmailBackend(ModelBackend):
    """
    Autentica usando email ao invés de username
    """
    def authenticate(self, request, username=None, password=None, **kwargs):
        try:
            # Tentar encontrar usuário por email (case-insensitive)
            user = User.objects.get(email__iexact=username)
        except User.DoesNotExist:
            # Também tentar por username direto
            try:
                user = User.objects.get(username__iexact=username)
            except User.DoesNotExist:
                return None
        
        # Verificar senha
        if user.check_password(password):
            return user
        return None
