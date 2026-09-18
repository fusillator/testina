#RUN pip install --no-cache-dir -r requirements.txt
#RUN if [ "$ENVIRONMENT" = "dev" ]; then \
#        pip install -e .[dev]; \
#    else \
#        pip install .; \
#    fi

FROM python:3.14-slim AS base
WORKDIR /app
COPY pyproject.toml ./

FROM base AS local
COPY requirements-lock-dev.txt ./
RUN pip install --no-cache-dir --require-hashes -r requirements-lock-dev.txt \
 && mkdir -p src/testina \
 && touch src/testina/__init__.py \
 && pip install --no-deps -e . 
CMD [ "pytest" ]

FROM base AS dev
COPY requirements-lock-dev.txt ./
COPY src/testina ./src/testina
COPY tests ./tests
RUN pip install --no-cache-dir --require-hashes -r requirements-lock-dev.txt \
 && pip install --no-deps .
CMD [ "pytest" ]

FROM base AS prod
COPY requirements-lock.txt ./
COPY src/testina ./src/testina
RUN pip install --no-cache-dir --require-hashes -r requirements-lock.txt \
 && pip install --no-deps .
ARG PORT=5000
EXPOSE $PORT
ENV FLASK_RUN_PORT=$PORT
ENV FLASK_RUN_HOST=0.0.0.0
CMD ["flask", "--app", "testina:create_app", "run"]
