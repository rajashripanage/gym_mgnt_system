# FitZone – Gym Management System

A full-stack gym management application: a **public website**, an **owner/admin console**, a **member self-service portal** and a **REST API**.

**Stack:** Java 17 · Spring Boot 3.2 · Spring Security · Spring Data JPA · MySQL 8 · Thymeleaf + Bootstrap 5 · Maven · Docker

---

## Features

| Area | What it does |
|---|---|
| Public website | Plans, trainers, online member registration |
| Authentication | Role based login (ADMIN / MEMBER), BCrypt passwords, forgot / reset password (email or demo link) |
| Members | Full profile page for the owner: details, plan, trainer, invoices, payments, attendance, queries, private notes, activate / deactivate |
| Trainers & Plans | CRUD, assign / change / remove trainer, "members without trainer" warnings |
| Billing | Invoices with plan-type discount + 18 % GST, extra discount, due date, overdue flag, printable invoice |
| Payments | Receipt numbers (`RCPT-00001`), transaction reference, printable receipt |
| Attendance | Check-in / check-out with duration, monthly and total visit counts |
| Queries | Member → owner support threads (OPEN → REPLIED → CLOSED) |
| Announcements & Notifications | Notices on every member portal; in-app notifications with unread badge for owner and members |
| Member portal | Read-only view of plan, validity, trainer, invoices, receipts, attendance, notices; edit own profile; change password |
| Dashboard | Collections today, overdue invoices, open queries, expiring memberships, latest notifications |
| REST API | JSON endpoints secured with HTTP Basic (see below) |

## Quick start

### Option 1 – Try it instantly (no database needed)
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=demo
```
Uses an in-memory H2 database with demo data. Open <http://localhost:8080>.

### Option 2 – Docker (app + MySQL)
```bash
cp .env.example .env        # set your own passwords
docker compose up --build
```

### Option 3 – Local MySQL
1. Install JDK 17+ and MySQL 8 (the `gym_db` database is created automatically).
2. Set `DB_USERNAME` / `DB_PASSWORD` (defaults: `root` / `root`) or edit `application.properties`.
3. `mvn spring-boot:run`  (or import into STS / IntelliJ and run `GymManagementApplication`).

### Demo logins (seeded when `SEED_DEMO_DATA=true`)
| Role | Login | Password | Opens |
|---|---|---|---|
| Admin | `admin` | `admin123` | `/dashboard` |
| Member | `amit@example.com` | `member123` | `/portal` |
| Member (pending) | `neha@example.com` | `member123` | `/portal` |

> ⚠️ Change `ADMIN_PASSWORD` and set `SEED_DEMO_DATA=false` for any real deployment.

## Configuration (environment variables)

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `8080` | HTTP port |
| `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` | local MySQL / `root` / `root` | Database |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` / `ADMIN_EMAIL` | `admin` / `admin123` / `admin@fitzone.com` | Owner account |
| `SEED_DEMO_DATA` | `true` | Insert sample data on first run |
| `DDL_AUTO` | `update` | Hibernate schema mode |
| `SPRING_MAIL_HOST`, `SPRING_MAIL_PORT`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, `MAIL_FROM` | unset | Real password-reset emails. Without them the reset link is shown on screen and logged (demo mode) |

## Workflow

1. A visitor **registers** on the website → status *Pending*; owner and member are notified.
2. The owner opens **Members → profile**: assign trainer / plan → generate first invoice (membership starts) → record payment (receipt) → mark attendance → renew later. Each step notifies the member.
3. The member follows everything in the **portal**, and raises a **query** if in doubt; the owner replies from *Queries*.

## REST API (HTTP Basic: admin account)

| Method | URL | Description |
|---|---|---|
| GET | `/api/members?q=` | List / search members |
| GET / DELETE | `/api/members/{id}` | Get / delete member |
| POST | `/api/members?planId=1&trainerId=1` | Add member (JSON body) |
| PUT | `/api/members/{id}/trainer?trainerId=` | Assign trainer |
| GET / POST | `/api/trainers`, `/api/plans` | Lists / create |
| GET | `/api/attendance?date=YYYY-MM-DD` | Attendance of a date |
| POST | `/api/attendance/{memberId}` | Mark today's attendance |
| GET / POST | `/api/invoices` (`?memberId=&planId=`) | List / generate invoice |
| GET / POST | `/api/payments` (`?invoiceId=&amount=&mode=&reference=`) | List / add payment |
| GET | `/api/dashboard` | Statistics |

```bash
curl -u admin:admin123 http://localhost:8080/api/dashboard
curl -u admin:admin123 -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@mail.com","phone":"9999999999","gender":"Male"}' \
  "http://localhost:8080/api/members?planId=1"
```

## Architecture

```
com.gym
├── controller   web (Thymeleaf) + REST controllers
├── service      business logic (billing, attendance, notifications, queries, password reset ...)
├── repository   Spring Data JPA repositories
├── model        JPA entities & enums (User → Member / Trainer, Invoice, Payment ...)
├── fee          Strategy pattern: Basic 0 % / Premium 5 % / VIP 10 % discount
├── config       Spring Security, demo-data seeding
├── dto          form objects
└── exception    custom exceptions + REST error handler
```

**Design notes:** encapsulated entities; inheritance (`User` → `Member`, `Trainer`); polymorphism through `FeeCalculator`; collections/streams for dashboards; centralised exception handling.

**Billing formula:** `Total = (Plan price − plan-type discount − extra discount) + 18 % GST`. Generating an invoice renews the membership expiry.

## Testing

```bash
mvn test
```
Unit tests for fee calculation and Spring Boot smoke tests (context start, public pages, API security) on the in-memory `demo` profile.

## Roadmap ideas
Online payments (UPI / card gateway), SMS / WhatsApp reminders, Flyway migrations, trainer login, reports export (PDF / Excel).
