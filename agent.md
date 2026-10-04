# Agent Instructions: Project "Tech Dossier" MVP

## 1. System Role & Objective

You are an expert Full-Stack Application Architect and Product Engineer. Your objective is to scaffold, build, and deliver a production-ready Minimum Viable Product (MVP) for "The Tech Dossier" (working title).

This platform is a gamified, intelligence-themed learning archive designed to build digital literacy and fluency. It must be highly flexible, designed to deliver "Intel Briefs" (micro-lessons) on anything from basic word processing and internet security to full-stack system architecture and AI prompt engineering. The platform replaces traditional academic UI with a tactical, current-affairs dashboard.

## 2. Platform Philosophy & Constraints

- **Broad Digital Literacy:** The data schema and UI must not assume a topic is code-related. A module on "How to format a Word Document" must use the same component architecture as "Understanding REST APIs."
- **The Intelligence Aesthetic:** Use terms like "Dossiers" instead of lessons, "Clearances" instead of levels, and "Field Tests" instead of quizzes.
- **Dynamic UI Scaling:** The frontend must support theme/state changes based on the user's "Clearance Level" (e.g., transitioning from a clean, bright UI at Level 1 to a dense, dark-mode terminal aesthetic at Level 4).

## 3. Technology Stack & Architecture

Ensure the codebase is optimized for fast execution, serverless edge deployment, and scalable relational data.

- **Frontend Framework:** Nuxt.js (Vue 3 ecosystem) utilizing Server-Side Rendering (SSR) for optimal performance and SEO.
- **Styling:** Tailwind CSS. Implement a robust configuration for multiple themes (Standard, Developer Console, Tactical Dark, Terminal) controlled via global state.
- **Backend / Database / Auth:** Supabase. Utilize PostgreSQL for relational data integrity, Supabase Auth for session management, and Row Level Security (RLS) to restrict classified module access based on user clearance.
- **Deployment Target:** Configure build outputs for edge networks (e.g., Cloudflare Pages/Workers).

## 4. Core Data Models (Supabase PostgreSQL)

Initialize the database with the following foundational schema to ensure maximum flexibility across the 2,000+ planned topics:

- **`users`:** `id`, `email`, `clearance_level` (integer, default: 1), `intel_points` (integer, default: 0), `created_at`.
- **`dossiers` (Topics):** `id`, `title`, `slug`, `category` (e.g., 'Workspace Ops', 'System Architecture'), `required_clearance` (integer), `is_code_related` (boolean), `content_markdown`, `briefing_summary` (short description).
- **`field_tests` (Assessments):** `id`, `dossier_id`, `scenario_description`, `test_type` (e.g., 'interactive_simulation', 'phishing_spotter', 'api_debug'), `passing_criteria`.
- **`user_progress`:** `id`, `user_id`, `dossier_id`, `status` ('locked', 'available', 'completed'), `completed_at`.

## 5. MVP Feature Requirements

### A. The Briefing Dashboard (Home)

- **News Ticker/Daily Dispatch:** A dynamic header that links a simulated current tech event to a foundational dossier (e.g., "Global IT Outage → Read the 'DNS Routing' Dossier").
- **Active Missions:** A card-based grid showing dossiers available at the user's current clearance level.
- **Restricted Archives:** Grayed-out or "redacted" cards showing high-level topics the user cannot access yet, building anticipation.

### B. The Dossier View (Content Consumption)

- Render content using a robust Markdown parser to support text, inline code snippets, and embedded visual diagrams.
- **ELI5 Toggle:** A state toggle on the page that swaps the technical text for an analogy-based explanation.

### C. The Clearance Engine (Gamification)

- Global state management (using Pinia or Vue's Reactivity API) that listens to the `user.clearance_level`.
- When a user passes a transitionary `field_test`, trigger a UI animation (e.g., "Clearance Upgraded: Level 2 Field Operative") and swap the Tailwind root theme class to instantly change the platform's visual aesthetic.

## 6. Execution Steps for the Agent

1.  **Project Initialization:** Scaffold the Nuxt.js application with Tailwind CSS and install Supabase client libraries.
2.  **Database Seeding:** Create the Supabase tables and insert 10 sample dossiers representing the MVP "Survival Kits" (mixing Word Processing, AI, and Web Architecture).
3.  **Authentication Flow:** Build the login/signup screens and integrate Supabase Auth.
4.  **UI Component Library:** Build reusable Vue components for Dossier Cards, the Progress/Clearance Bar, and the ELI5 Toggle switch.
5.  **Dashboard & Routing:** Implement dynamic routing (`/dossier/[slug]`) and build the main dashboard fetching data via Supabase.
6.  **State & Theming:** Implement the state logic that checks the user's clearance level and applies the correct global CSS variables.
