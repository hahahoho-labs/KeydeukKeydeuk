# Feedback API & DB Spec (MVP)

## 1) API

- Endpoint: `POST https://<SUPABASE_PROJECT_REF>.supabase.co/functions/v1/feedback`
- Method: `POST`
- Content-Type: `application/json`
- Auth (MVP):
  - Edge Function `Verify JWT`를 끈 경우: Authorization 헤더 없이 호출 가능
  - `Verify JWT`를 켠 경우: `Authorization: Bearer <anon_key_or_jwt>` 필요

### Request Body

```json
{
  "email": "user@example.com",
  "title": "요약 제목",
  "message": "상세 내용",
  "appVersion": "1.0.0",
  "buildNumber": "100",
  "osVersion": "14.6.1",
  "osName": "macOS",
  "localeIdentifier": "ko_KR",
  "bundleID": "com.example.KeydeukKeydeuk",
  "installationId": "b4fc58f0-2a57-43f2-8888-cf92b90f2d26"
}
```

### Validation Rules

- `title`: 필수, `1...50`자
- `message`: 필수, `1...500`자
- `email`: 선택, 최대 `120`자, 형식 검증
- `installationId`: 필수, 최대 `80`자 (앱 설치 단위 식별자)

### Response

- `200`: DB/GitHub/Discord 모두 정상
- `207`: DB 저장은 성공, 외부 채널(GitHub/Discord) 일부 실패
- `400`: 요청 body 검증 실패
- `401`: 인증 헤더 누락/유효하지 않음 (JWT 검증 켠 경우)
- `429`: 12시간 rate limit 초과 (`retryAfterSeconds` 반환)
- `500`: 서버 내부 오류

예시:

```json
{
  "submissionId": "uuid",
  "githubIssueUrl": "https://github.com/org/repo/issues/123",
  "channels": {
    "db": "ok",
    "github": "ok",
    "discord": "ok"
  },
  "partialFailure": false
}
```

---

## 2) DB (Postgres / Supabase)

Table: `public.feedback_submissions`

### Recommended Columns

- `id uuid primary key default gen_random_uuid()`
- `created_at timestamptz not null default now()`
- `source text not null default 'macos-app'`
- `email text null`
- `title text not null`
- `message text not null`
- `app_version text null`
- `build_number text null`
- `os_version text null`
- `os_name text null`
- `locale_identifier text null`
- `bundle_id text null`
- `delivery_status jsonb not null`
- `github_issue_url text null`
- `discord_message_id text null`
- `last_error text null`

### Constraints

- `feedback_submissions_title_len`: `char_length(title) between 1 and 50`
- `feedback_submissions_message_len`: `char_length(message) between 1 and 500`

### SQL: Title 제한 30 -> 50 업데이트

```sql
ALTER TABLE public.feedback_submissions
  DROP CONSTRAINT feedback_submissions_title_len;

ALTER TABLE public.feedback_submissions
  ADD CONSTRAINT feedback_submissions_title_len
  CHECK ((char_length((title)::text) >= 1) AND (char_length((title)::text) <= 50));
```

검증:

```sql
SELECT conname, pg_get_constraintdef(c.oid)
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname='public' AND t.relname='feedback_submissions' AND c.contype='c';
```

---

## 3) Edge Function Secrets (Supabase)

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `GITHUB_REPO` (`owner/repo`)
- `GITHUB_APP_ID`
- `GITHUB_APP_INSTALLATION_ID`
- `GITHUB_APP_PRIVATE_KEY` (PKCS#8 PEM)
- `DISCORD_WEBHOOK_URL`

---

## 4) macOS App Runtime Env (local/dev)

- `KEYDEUK_FEEDBACK_ENDPOINT`
- `KEYDEUK_FEEDBACK_AUTH_TOKEN` (JWT 검증 켠 경우만 필요)
