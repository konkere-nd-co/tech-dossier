-- 1. Create the dossiers table
CREATE TABLE IF NOT EXISTS public.dossiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL,
  required_clearance INTEGER NOT NULL DEFAULT 1,
  is_code_related BOOLEAN NOT NULL DEFAULT false,
  content_markdown TEXT NOT NULL,
  briefing_summary TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Insert the MVP seed data
INSERT INTO public.dossiers (title, slug, category, required_clearance, is_code_related, briefing_summary, content_markdown) VALUES

-- LEVEL 1: Civilian Observer (Daily Drivers)
(
  'The Workspace Ecosystem: Docs & Sheets', 
  'workspace-ecosystem', 
  'Workspace Ops', 
  1, 
  false, 
  'Mastering the basic tools of digital productivity.',
  '# The Workspace Ecosystem\n\nBefore you build the internet, you need to know how to operate on it. Word processors and spreadsheets are the original no-code tools. They allow you to structure thoughts, calculate data, and share information globally without writing a single line of code.'
),
(
  'How the Internet Actually Works', 
  'how-internet-works', 
  'Internet Basics', 
  1, 
  false, 
  'The physical reality of the web, from undersea cables to Wi-Fi.',
  '# How the Internet Actually Works\n\nThe cloud is just someone else''s computer. When you type a URL, your browser acts as a messenger, traveling through fiber-optic cables under the ocean to fetch files from a server thousands of miles away.'
),
(
  'Security 101: Passwords & Phishing', 
  'security-101', 
  'Security', 
  1, 
  false, 
  'Defending your digital identity from social engineering.',
  '# Security 101\n\nThe weakest link in any system isn''t the code; it''s the human. Using a password manager and understanding Two-Factor Authentication (2FA) is the equivalent of locking your front door instead of hiding the key under the mat.'
),

-- LEVEL 2: Field Operative (Builder Basics)
(
  'Web Architecture: HTML, CSS, & JS', 
  'web-architecture', 
  'Web Architecture', 
  2, 
  true, 
  'The holy trinity of frontend development.',
  '# Web Architecture\n\nThink of a website as a house. **HTML** is the wooden frame and foundation. **CSS** is the paint, the interior design, and the landscaping. **JavaScript** is the electricity and plumbing that makes the house actually function.'
),
(
  'System Logic: What is an API?', 
  'what-is-an-api', 
  'System Architecture', 
  2, 
  true, 
  'How different software applications talk to each other.',
  '# What is an API?\n\nAn Application Programming Interface (API) is a digital waiter. You sit at a restaurant (the frontend), look at the menu, and tell the waiter what you want. The waiter takes your order to the kitchen (the backend/database), gets your food, and brings it back to you.'
),
(
  'Databases: Relational vs. Document', 
  'databases-explained', 
  'System Architecture', 
  2, 
  true, 
  'Where and how digital information is stored for retrieval.',
  '# Databases Explained\n\nIf APIs are the waiters, the database is the pantry. A **Relational Database** (like PostgreSQL) is a highly organized filing cabinet with strict rules. A **Document Database** (like MongoDB) is a flexible storage box where you can throw things in quickly.'
),
(
  'Design Literacy: Whitespace & Typography', 
  'design-literacy', 
  'Design', 
  2, 
  false, 
  'Why some apps feel premium and others feel cluttered.',
  '# Design Literacy\n\nGood design is invisible. The secret to premium-looking applications isn''t flashy animations; it''s the aggressive use of whitespace (breathing room) and highly legible typography to guide the user''s eye naturally.'
),

-- LEVEL 3: System Specialist (Advanced Logic)
(
  'AI & LLMs: Predicting the Next Word', 
  'ai-and-llms', 
  'Artificial Intelligence', 
  3, 
  false, 
  'Demystifying Large Language Models and prompt engineering.',
  '# AI & LLMs\n\nAI models like ChatGPT are not "thinking" in the human sense; they are highly advanced autocomplete engines. By mastering prompt engineering, you are simply giving the engine better guardrails to predict the exact output you want.'
),
(
  'The IoT: Hardware Meets Software', 
  'iot-hardware', 
  'Hardware & IoT', 
  3, 
  false, 
  'How sensors and smart devices map the physical world.',
  '# The Internet of Things\n\nYour smart thermostat is essentially a tiny web server with a temperature sensor. IoT bridges the gap between digital data and physical reality, allowing software to measure, react to, and manipulate the real world.'
),
(
  'Tech Lore: The Browser Wars', 
  'browser-wars', 
  'Tech History', 
  3, 
  false, 
  'The historical battle that shaped the modern internet.',
  '# The Browser Wars\n\nBefore Chrome dominated the world, there was a fierce battle between Internet Explorer and Netscape. Understanding this history explains why web standards exist today and why building cross-browser applications used to be a nightmare.'
)
ON CONFLICT (slug) DO NOTHING;
