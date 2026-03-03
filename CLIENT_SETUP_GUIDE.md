# Download Binaries — Client Setup Guide

## What's Already Done (Infrastructure Side)

All the AWS infrastructure is already provisioned and running:

| Resource | Value |
|----------|-------|
| S3 Bucket | `clace-app-updates` |
| CloudFront Distribution ID | `E3S7CDB55JPURV` |
| CloudFront Domain | `d3g3cm3o5adesx.cloudfront.net` |
| Custom Domain | `updates.clace.ai` |
| IAM Role ARN (for GitHub Actions) | `arn:aws:iam::328991713666:role/clace-dev-ci-updater` |
| AWS Region | `us-east-2` |

The S3 bucket is private (not directly accessible). CloudFront serves files publicly over HTTPS.
The IAM role uses GitHub OIDC — no static AWS keys needed.

---

## What You Need To Do

### Step 1: Add the Workflow File to the Client Repo

Copy the file `.github/workflows/upload-binaries.yml` from this infra repo into the
`koushikmote02/Client` repo at the same path:

```
koushikmote02/Client/
  .github/
    workflows/
      upload-binaries.yml
```

Commit and push it to the default branch.

### Step 2: Add GitHub Secrets

Go to **GitHub → `koushikmote02/Client` → Settings → Secrets and variables → Actions → New repository secret**

Add these two secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_CI_ROLE_ARN` | `arn:aws:iam::328991713666:role/clace-dev-ci-updater` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `E3S7CDB55JPURV` |

That's it. Only two secrets. No AWS access keys needed — authentication happens via OIDC.

### Step 3: Create a Release

When you publish a GitHub release on `koushikmote02/Client` that has `.exe` and/or `.dmg`
files attached as release assets, the workflow will automatically:

1. Download the `.exe` and `.dmg` from the release
2. Upload them to S3 under `downloads/<version>/` (versioned)
3. Upload them to S3 under `downloads/latest/` (stable links)
4. Invalidate the CloudFront cache so changes go live immediately

You can also trigger it manually from the Actions tab → "Upload Binaries to S3" → "Run workflow"
and enter a tag like `v0.2.0`.

---

## Download Links for Your Website

### Stable "Latest" Links (always point to the most recent release)

These are the links to put on your website download page:

- **Windows:** `https://updates.clace.ai/downloads/latest/Clace-latest-setup.exe`
- **macOS:** `https://updates.clace.ai/downloads/latest/Clace-latest.dmg`

When a user clicks these, the file downloads automatically.

### Versioned Links (for linking to a specific version)

- **Windows:** `https://updates.clace.ai/downloads/<version>/<exact-filename>.exe`
- **macOS:** `https://updates.clace.ai/downloads/<version>/<exact-filename>.dmg`

Example for v0.2.0:
- `https://updates.clace.ai/downloads/0.2.0/Clace_0.2.0_x64-setup.exe`
- `https://updates.clace.ai/downloads/0.2.0/Clace_0.2.0_aarch64.dmg`

The exact filenames in the versioned path match whatever filenames are attached to the GitHub release.

---

## How It Works (Overview)

```
GitHub Release (private repo)
       │
       ▼
GitHub Actions workflow triggers
       │
       ▼  (authenticates via OIDC — no keys)
AWS S3 (clace-app-updates bucket)
       │
       ▼
CloudFront CDN (updates.clace.ai)
       │
       ▼
User clicks download link → file downloads
```

- The GitHub repo stays private — no one can see your source code
- The binaries are served publicly through CloudFront (HTTPS, fast, globally cached)
- No AWS access keys are stored anywhere — GitHub OIDC handles auth securely
- Every new release automatically updates the "latest" download links

---

## Troubleshooting

**Workflow fails with "could not assume role":**
- Make sure the secret `AWS_CI_ROLE_ARN` is set correctly
- The OIDC trust is scoped to `repo:koushikmote02/Client:*` — the workflow must run from that repo

**Files not showing up at the download URL:**
- CloudFront cache invalidation takes ~30 seconds. Wait a minute and try again.
- Check the workflow logs in GitHub Actions to see if the upload succeeded.

**Want to re-upload an existing release:**
- Go to Actions → "Upload Binaries to S3" → "Run workflow" → enter the tag (e.g., `v0.2.0`)
