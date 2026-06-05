import base64
from rest_framework import permissions, status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView
from .services import deepseek


class SolveQuestionView(APIView):
    """AI solves a math question with step-by-step reasoning + concours tips."""
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [JSONParser, FormParser]

    def post(self, request):
        question_text = request.data.get('question', '')
        subject = request.data.get('subject', '')
        choices = request.data.get('choices', [])
        if not question_text:
            return Response(
                {'detail': 'Question text is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = deepseek.solve_question(question_text, subject, choices)
        return Response({'result': result})


class GenerateSimilarView(APIView):
    """AI generates a similar question to the one provided."""
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [JSONParser, FormParser]

    def post(self, request):
        question_text = request.data.get('question', '')
        subject = request.data.get('subject', '')
        if not question_text:
            return Response(
                {'detail': 'Question text is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = deepseek.generate_similar(question_text, subject)
        return Response({'result': result})


class AiChatView(APIView):
    """AI chat — send text, get math advice."""
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    def post(self, request):
        user_text = request.data.get('text', '')
        if not user_text:
            return Response(
                {'detail': 'Text is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        result = deepseek.ai_chat(user_text, image_base64=None)
        return Response({'result': result})


class OcrView(APIView):
    """OCR — extract text from an image. Returns text for user to validate."""
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [FormParser, MultiPartParser]

    def post(self, request):
        image_file = request.FILES.get('image')
        if not image_file:
            return Response(
                {'detail': 'Image is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        image_b64 = base64.b64encode(image_file.read()).decode('utf-8')
        text = deepseek._ocr_image(image_b64)
        if text:
            return Response({'text': text})
        return Response(
            {'detail': 'OCR failed — could not extract text from image'},
            status=status.HTTP_422_UNPROCESSABLE_ENTITY,
        )
