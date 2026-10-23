FROM python:3.12-alpine
WORKDIR /app
COPY server.py .
RUN addgroup -S app && adduser -S -G app app
USER app
EXPOSE 8000
CMD ["python", "server.py"]