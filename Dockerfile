#RUN pip install --no-cache-dir -r requirements.txt
#RUN if [ "$ENVIRONMENT" = "dev" ]; then \
#        pip install -e .[dev]; \
#    else \
#        pip install .; \
#    fi

FROM python:3.11-slim AS base
WORKDIR /app
COPY src/testina ./src/testina

FROM base as dev
COPY src/tests ./src/tests
COPY pyproject.toml pytest.ini ./ 
RUN pip install --no-cache-dir ".[dev]"
CMD [ "pytest" ]

FROM base as prod
COPY pyproject.toml . 
RUN pip install --no-cache-dir .
ARG PORT=5000
EXPOSE $PORT
ENV FLASK_RUN_PORT=$PORT
ENV FLASK_RUN_HOST=0.0.0.0
CMD ["flask", "--app", "testina:create_app", "run"]
