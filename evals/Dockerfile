# Self-contained eval image: opencode (pinned) + Playwright (pinned) + Chromium.
# The agent runs as `agent`; the system under test runs as `sut` from a private directory.
FROM node:22-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 curl ca-certificates util-linux \
 && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai@1.18.34 && opencode --version

ENV PLAYWRIGHT_BROWSERS_PATH=/opt/pw
RUN mkdir -p /opt/qa && cd /opt/qa && npm init -y >/dev/null \
 && npm install @playwright/test@1.63.0 \
 && npx playwright install --with-deps chromium \
 && chmod -R a+rX /opt/qa /opt/pw

RUN useradd --create-home --uid 1100 agent && useradd --no-create-home --uid 1001 sut
WORKDIR /work
