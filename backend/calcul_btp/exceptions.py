from rest_framework.views import exception_handler


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return None

    detail = response.data
    if isinstance(detail, dict) and "code" in detail:
        response.data = detail
        return response

    code = "VALIDATION_ERREUR"
    if response.status_code == 401:
        code = "TOKEN_INVALIDE"
    elif response.status_code == 403:
        code = "ABONNEMENT_REQUIS" if "ABONNEMENT" in str(detail) else "FORBIDDEN"
    elif response.status_code == 409:
        code = "CONFLIT_SYNC"

    message = detail
    if isinstance(detail, dict):
        message = detail.get("detail", detail)
    if isinstance(message, list):
        message = message[0]

    response.data = {
        "status": "error",
        "code": code,
        "message": str(message),
        "http_status": response.status_code,
    }
    return response
