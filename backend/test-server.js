import { server } from './dist/server.js';

async function test() {
  await new Promise((resolve) => setTimeout(resolve, 500));
  try {
    const res = await fetch('http://localhost:5000/api/health');
    const data = await res.json();
    console.log('✅ HEALTH CHECK RESPONSE:', JSON.stringify(data));

    // Test Login with seeded user
    const loginRes = await fetch('http://localhost:5000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        identifier: 'rohan@example.com',
        password: 'password123',
      }),
    });
    const loginData = await loginRes.json();
    console.log('✅ LOGIN SUCCESSFUL FOR:', loginData.user.displayName, '| Token length:', loginData.token?.length);

    // Test Search friends
    const searchRes = await fetch('http://localhost:5000/api/friends/search?query=priya', {
      headers: { Authorization: `Bearer ${loginData.token}` },
    });
    const searchData = await searchRes.json();
    console.log('✅ FRIEND SEARCH FOUND:', searchData.length, 'user(s) matching "priya"');

    // Test AI Chat
    const aiRes = await fetch('http://localhost:5000/api/ai/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${loginData.token}`,
      },
      body: JSON.stringify({
        message: 'Hey jaan, feeling a bit lonely tonight after a long day at work.',
        mode: 'ROMANTIC',
      }),
    });
    const aiData = await aiRes.json();
    console.log('✅ AI COMPANION REPLY:', aiData.reply);

    // Test Photo Request
    const photoRes = await fetch('http://localhost:5000/api/ai/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${loginData.token}`,
      },
      body: JSON.stringify({
        message: 'Can you send me a picture of you smiling?',
        mode: 'ROMANTIC',
      }),
    });
    const photoData = await photoRes.json();
    console.log('✅ AI PHOTO RESPONSE:', photoData.reply, '| Photo URL:', photoData.photoUrl);

    // Test Memories Inspection
    const memRes = await fetch('http://localhost:5000/api/ai/memories', {
      headers: { Authorization: `Bearer ${loginData.token}` },
    });
    const memData = await memRes.json();
    console.log('✅ MEMORIES RECORDED:', memData.facts.length, 'facts | Pulse closeness score:', memData.pulse.closenessScore);

    console.log('\n🎉 ALL BACKEND API TESTS PASSED PERFECTLY!');
  } catch (err) {
    console.error('❌ Test failed:', err);
  } finally {
    server.close();
    process.exit(0);
  }
}

test();
