# Secrets

setup-qa needs exactly one secret: your NaN API key.

- It lives only in the `NAN_API_KEY` environment variable. The config reads it at startup with `{env:NAN_API_KEY}`; the key is never written into any file of this repository or of your opencode config.
- To set it permanently, add this line to `~/.zshrc` and open a new terminal:

  ```bash
  export NAN_API_KEY="<your key>"
  ```

- Never commit the key, paste it into a prompt, or put it in a `.env` file inside a project you share.
- The agent is configured to refuse edits to `.env`, `*.pem`, `*.key`, `id_rsa*` and `secrets/` paths.
- If a key is exposed, revoke it in your NaN account and create a new one.

Before publishing changes to this repository run `scripts/scan-public.sh`; it fails when it finds secret-shaped strings, personal paths, e-mail addresses or names from a private list.
