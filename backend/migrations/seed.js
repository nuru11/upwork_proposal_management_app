const path = require('path');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

async function upsertTemplate(connection, {
  id, userId, name, body, inspiredFrom, language = 'english', now,
}) {
  await connection.execute(
    `INSERT INTO templates (
      id, user_id, name, body, inspired_from, language, project_type, is_favorite,
      created_at, updated_at, deleted_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, NULL)
    ON DUPLICATE KEY UPDATE
      name = VALUES(name),
      body = VALUES(body),
      inspired_from = VALUES(inspired_from),
      language = VALUES(language),
      project_type = VALUES(project_type),
      is_favorite = VALUES(is_favorite),
      updated_at = VALUES(updated_at),
      deleted_at = NULL`,
    [id, userId, name, body, inspiredFrom, language, 'mobileApp', now, now],
  );
}

async function seed() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  try {
    const username = 'nuru';
    const password = 'nuru@123';
    const passwordHash = await bcrypt.hash(password, 10);
    const now = new Date().toISOString().slice(0, 23).replace('T', ' ');

    const [existing] = await connection.execute(
      'SELECT id FROM users WHERE username = ? LIMIT 1',
      [username],
    );

    let userId;
    if (existing.length > 0) {
      userId = existing[0].id;
      await connection.execute(
        `UPDATE users
         SET password_hash = ?, updated_at = ?
         WHERE username = ?`,
        [passwordHash, now, username],
      );
      console.log(`Updated user "${username}".`);
    } else {
      userId = uuidv4();
      await connection.execute(
        `INSERT INTO users (id, username, password_hash, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?)`,
        [userId, username, passwordHash, now, now],
      );
      console.log(`Created user "${username}".`);
    }

    const templateId = '7c8f2e1a-4b3d-4f6e-9a12-8d5e6f7a8b9c';
    const templateBody = `Hi [Client Name / "there"],
Recently I built a similar project, and I have solid experience making this type of product competitive in the market.
[Project Type] apps mostly fail because of [UX/Business Flaw]. In fact, studies show that [X%] of users abandon [Project Type] due to [Specific Friction Point]. Research from [Authoritative Source] highlights that [Key Solution/Metric] has a significantly higher impact on conversions and user retention than [Secondary Feature/Distraction].
From my experience, similar apps also suffer from hidden technical issues that don't appear until they go live in production—most notably in [Critical Technical Bottleneck].
Here is how I solve both:
1. UX/UI Strategy: I build interfaces focused on [Key UX Fix] to keep users engaged and buying.
2. Technical Architecture: I implement [Technical Solution] so your app stays fast, responsive, and bug-free under real-world load.
For this project I would use [App Stack] because [App Stack Reason]. For the backend I would go with [Backend Stack]. For hosting, [Hosting Suggestion].
You can check out a similar project I completed here: [Link to Demo / Portfolio]
Does this stack work for you?
One question that would help me make this more competitive: [Business Question]
Happy to jump on a quick chat.
Best,
[Your Name]`;
    const inspiredFrom = `Hi,

I recently built a dual-app system (one for users and one for drivers), so I have a lot of experience making this kind of project work smoothly.

On-demand apps mostly fail because of a clunky booking experience and poor live tracking. Around 60% of users delete driver/customer apps simply because the map lags, prices aren't clear, or booking takes too many clicks. UX studies show that simple, instant booking is way more important to users than fancy extra features.

From my experience, these apps also face technical issues that only show up after launch—mostly with background GPS tracking and live updates dropping when a driver loses phone signal or switches apps.

Here is how I make sure your project avoids these problems:
* Driver & Customer UX: Clean, super simple screens so customers can book in 2 clicks and drivers can easily accept jobs without confusion.
* Reliable Live Updates: Smart background tracking that stays connected and syncs automatically, even if the network is weak.

I'd use Flutter here because one codebase stays fast on both phones. Backend I'd keep on Node.js. At the start a VPS keeps cost low, and we can move to the cloud later if traffic grows.

You can check out a similar mobile app I built here: [Insert Link]

Does this stack work for you?
One question that would help me make this more competitive: when someone opens the app, what should feel easy first — booking in a few taps, or seeing a clear price before they confirm?
Happy to jump on a quick chat.

Best,`;

    await upsertTemplate(connection, {
      id: templateId,
      userId,
      name: 'UX + technical bottleneck',
      body: templateBody,
      inspiredFrom,
      language: 'english',
      now,
    });
    console.log('Upserted template "UX + technical bottleneck".');

    const proofFirstId = '3e9a1c4b-7d2f-4e8a-9b1c-5f6d8e0a2c4b';
    const proofFirstBody = `Hi [Client Name / "there"],

I've helped [X] [App / startup type] [Measurable Result] using [Similar Approach].

[Specific Proof From a Similar Build]. You can see that app here: [Link to Similar Project].

Your main challenge looks like [Core Job Challenge]. Here's my 3-step plan:
1. [Step 1 — first-week UX / first-open action]
2. [Step 2 — the reliability piece that usually breaks after launch]
3. [Step 3 — store-ready build so review doesn't stall you]

[Likely Objection] — [Short answer in plain talk].

Quick win you can do right now: [One change they can make on the current flow or listing today].

[Expert Question that baselines the work]

I'm free for a 10-minute call today to walk through [Their Goal].
Best,`;
    const proofFirstInspired = `Hi,

I've helped 2 on-demand startups get users booking in 2 taps using the same dual-app setup (customers + drivers).

On one of those apps, live tracking kept updating when a driver's signal dropped. You can see that build here: [Insert Link].

Your main challenge looks like people leaving because booking takes too many taps or the map lags. Here's my 3-step plan:
1. First-open screen is one action — book or request — with a clear price.
2. Background tracking that stays connected when the driver switches apps or hits a weak network.
3. Store-ready build so review doesn't stall you after the app works on a device.

You might be thinking of hiring two native teams — one Flutter codebase ships both stores and stays cheaper to change later.

Quick win you can do right now: if booking is more than two steps, cut it to one screen with the price visible. That's where most of these apps lose people.

Have you already mapped the first-open path — book in a few taps vs show a clear price first? That gives us a baseline before we change the flow.

I'm free for a 10-minute call today to walk through week one.
Best,`;

    await upsertTemplate(connection, {
      id: proofFirstId,
      userId,
      name: 'Proof-first 5-section',
      body: proofFirstBody,
      inspiredFrom: proofFirstInspired,
      language: 'english',
      now,
    });
    console.log('Upserted template "Proof-first 5-section".');

    const proofFirstArId = '8f2b4d6a-1c3e-4f7b-9a0d-2e5c7b1d4f6a';
    const proofFirstArBody = `مرحبا [Client Name / ""],

ساعدت [X] [App / startup type] يحقّقون [Measurable Result] باستخدام [Similar Approach].

[Specific Proof From a Similar Build]. تقدر تشوف التطبيق هنا: [Link to Similar Project].

أكبر تحدي عندك يبدو [Core Job Challenge]. هذي خطتي من ٣ خطوات:
1. [Step 1 — first-week UX / first-open action]
2. [Step 2 — the reliability piece that usually breaks after launch]
3. [Step 3 — store-ready build so review doesn't stall you]

[Likely Objection] — [Short answer in plain talk].

خطوة سريعة تقدر تعملها الحين: [One change they can make on the current flow or listing today].

[Expert Question that baselines the work]

أقدر أتفرّغ لمكالمة ١٠ دقايق اليوم ونمشي [Their Goal].
مع التحية،`;
    const proofFirstArInspired = `مرحبا،

ساعدت ٢ من أصحاب تطبيقات الطلبات يحقّقون حجز بلمستين باستخدام نفس نظام التطبيقين (عملاء + سائقين).

في واحد من هالتطبيقات، التتبع المباشر كمّل تحديث حتى لو إشارة السائق ضعفت. تقدر تشوف التطبيق هنا: [Insert Link].

أكبر تحدي عندك يبدو إن الناس تطلع لأن الحجز يحتاج لمسات كثيرة أو الخريطة تتقطع. هذي خطتي من ٣ خطوات:
1. أول شاشة تكون حركة واحدة — احجز أو اطلب — والسعر واضح.
2. تتبع في الخلفية يفضل متصل حتى لو السائق بدّل التطبيق أو الشبكة ضعفت.
3. نسخة جاهزة للمتاجر عشان المراجعة ما تعطّلك بعد ما التطبيق يشتغل على الجهاز.

ممكن تكون تفكر توظّف فريقين أصليين — كود Flutter واحد ينزل على المتجرين ويبقى أرخص لو تغيّر شيء لاحقاً.

خطوة سريعة تقدر تعملها الحين: إذا الحجز أكثر من خطوتين، خلّه شاشة واحدة والسعر ظاهر. هنا أغلب هالتطبيقات تخسر الناس.

هل رسمت مسار أول فتح — حجز بلمسات قليلة ولا سعر واضح أولاً؟ هذا يعطينا خط أساس قبل ما نغيّر التدفق.

أقدر أتفرّغ لمكالمة ١٠ دقايق اليوم ونمشي أسبوع الشغل الأول.
مع التحية،`;

    await upsertTemplate(connection, {
      id: proofFirstArId,
      userId,
      name: 'Proof-first 5-section (AR)',
      body: proofFirstArBody,
      inspiredFrom: proofFirstArInspired,
      language: 'arabic',
      now,
    });
    console.log('Upserted template "Proof-first 5-section (AR)".');

    const researchHookId = '5a7c9e2b-8d1f-4c3a-b6e0-9f2d4a8c1b7e';
    const researchHookBody = `Hi [Client Name / "there"],
I went through [What I Looked At]; [Specific Compliment]. I like that, and when I searched [Market] apps like [Named Competitor], I found [Competitor Insight], so I'd start with [Short Opening Suggest].

If you launch in [Market], the direct competitors are [Direct Competitors]. To win there you'd need [Must-Have Market Features]. Their weak spots are [Competitor Downsides], so we can [Our Angle To Win].

Those apps usually got the first wave of downloads from [Early Growth Tactic]. I'd use that same path, then keep users with [Retention Angle].

I'd ship this with [App Stack] because [App Stack Reason]. Backend [Backend Stack]. Hosting: [Hosting Suggestion].
You can see a similar app here: [Link to Similar Project].

[Expert Question that baselines the work]
Happy to jump on a quick chat.
Best,
[Your Name]`;
    const researchHookInspired = `Hi,

I went through your dual-app booking idea; the customer + driver split is the right call. I like that, and when I searched Saudi apps like Jahez, I found they win on ordering in a few taps, so I'd start with a 2-tap first open.

If you launch in Saudi / GCC, the direct competitors are Jahez, HungerStation, and Careem. To win there you'd need Arabic-first UI, local payments like Mada, and a map that doesn't lag. Their weak spots are messy first-open flows and tracking that drops on weak networks, so we can win on a 2-tap book and live tracking that stays up.

Those apps usually got the first wave of downloads from restaurant partnerships and store featuring, not from a huge ad budget. I'd use that same path, then keep users with a clear price before they confirm and a map that keeps updating.

I'd ship this with Flutter because one codebase stays fast on both phones. Backend I'd keep on Node.js. At the start a VPS keeps cost low, and we can move to the cloud later if traffic grows.
You can see a similar app here: [Insert Link].

When someone opens the app in Riyadh, what should feel easy first — booking in a few taps, or seeing a clear price before they confirm?
Happy to jump on a quick chat.
Best,`;

    await upsertTemplate(connection, {
      id: researchHookId,
      userId,
      name: 'Research hook — liked / found',
      body: researchHookBody,
      inspiredFrom: researchHookInspired,
      language: 'english',
      now,
    });
    console.log('Upserted template "Research hook — liked / found".');

    const researchHookArId = '6b8d0f3c-9e2a-4d5b-a7c1-0e3f5b9d2c8a';
    const researchHookArBody = `مرحبا [Client Name / ""],
شفت [What I Looked At]؛ [Specific Compliment]. عجبني كذا، ولما بحثت تطبيقات [Market] زي [Named Competitor]، لقيت [Competitor Insight]، فبأبدأ بـ [Short Opening Suggest].

لو تطلق في [Market]، المنافسين المباشرين [Direct Competitors]. عشان تفوز هناك تحتاج [Must-Have Market Features]. نقاط ضعفهم [Competitor Downsides]، فتقدر [Our Angle To Win].

هالتطبيقات عادة أول تحميلاتهم جت من [Early Growth Tactic]. بنفس الطريق، وبعدين نمسك المستخدم بـ [Retention Angle].

بأبنيه بـ [App Stack] لأن [App Stack Reason]. الباكند [Backend Stack]. الاستضافة: [Hosting Suggestion].
تقدر تشوف تطبيق مشابه هنا: [Link to Similar Project].

[Expert Question that baselines the work]
نقدر نتكلم بسرعة.
مع التحية،`;
    const researchHookArInspired = `مرحبا،

شفت فكرة تطبيق الحجز (عملاء + سائقين)؛ فصل الطرفين قرار صحيح. عجبني كذا، ولما بحثت تطبيقات السعودية زي جاهز، لقيت إنهم يفوزون بالطلب في كم لمسة، فبأبدأ بفتحة بلمستين.

لو تطلق في السعودية / الخليج، المنافسين المباشرين جاهز وهنقرستيشن وكريم. عشان تفوز هناك تحتاج واجهة عربية أولاً، دفع محلي مثل مدى، وخريطة ما تتقطع. نقاط ضعفهم أول شاشة مزدحمة وتتبع يسقط على شبكة ضعيفة، فتقدر تفوز بحجز بلمستين وتتبع يفضل شغال.

هالتطبيقات عادة أول تحميلاتهم جت من شراكات المطاعم وظهور في المتجر، مو من ميزانية إعلان ضخمة. بنفس الطريق، وبعدين نمسك المستخدم بسعر واضح قبل التأكيد وخريطة تحدّث حالها.

بأبنيه بـ Flutter لأن كود واحد يبقى سريع على الجوالين. الباكند Node.js. في البداية VPS يبقي التكلفة منخفضة، ونقدر ننتقل للسحابة لو الزحمة زادت.
تقدر تشوف تطبيق مشابه هنا: [Insert Link].

لما أحد يفتح التطبيق في الرياض، وش المفروض يكون سهل أولاً — حجز بكم لمسة، ولا سعر واضح قبل التأكيد؟
نقدر نتكلم بسرعة.
مع التحية،`;

    await upsertTemplate(connection, {
      id: researchHookArId,
      userId,
      name: 'Research hook — liked / found (AR)',
      body: researchHookArBody,
      inspiredFrom: researchHookArInspired,
      language: 'arabic',
      now,
    });
    console.log('Upserted template "Research hook — liked / found (AR)".');
  } finally {
    await connection.end();
  }
}

seed().catch((err) => {
  console.error('Seed failed:', err.message);
  process.exit(1);
});
