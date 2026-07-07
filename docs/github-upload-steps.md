# GitHub Upload Steps

Use these steps when updating the existing GitHub repository with this packaged project.

## 1. Unzip the package

```bash
unzip Ubuntu-Server-Hardening-Blue-Team-GITHUB-READY.zip
```

## 2. Copy the contents into your existing local repository

If your existing repository is located at `~/Ubuntu-Server-Hardening-Blue-Team`, copy the unzipped contents into it:

```bash
cp -r Ubuntu-Server-Hardening-Blue-Team/* ~/Ubuntu-Server-Hardening-Blue-Team/
cp -r Ubuntu-Server-Hardening-Blue-Team/.github ~/Ubuntu-Server-Hardening-Blue-Team/
cp Ubuntu-Server-Hardening-Blue-Team/.gitignore ~/Ubuntu-Server-Hardening-Blue-Team/
```

## 3. Confirm the folders exist

```bash
cd ~/Ubuntu-Server-Hardening-Blue-Team
ls -la
ls -la docs
ls -la evidence
ls -la evidence/screenshots
```

You should see the `docs/` and `evidence/` folders.

## 4. Commit and push

```bash
git status
git add .
git commit -m "Add full Ubuntu hardening lab evidence and procedures"
git push origin main
```

## 5. Confirm on GitHub

Refresh the repository page in the browser and confirm that these folders are visible:

```text
docs/
evidence/
evidence/screenshots/
scripts/
```
