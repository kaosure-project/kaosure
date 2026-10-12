// Called by a trusted scheduler, never from the Flutter client.
Deno.serve(async (req: Request) => {
  const secret = Deno.env.get('KAOID_WORKER_SECRET');
  if (!secret || req.headers.get('x-worker-secret') !== secret) return new Response('Unauthorized', {status:401});
  const key = Deno.env.get('RESEND_API_KEY');
  const from = Deno.env.get('KAOID_MAIL_FROM');
  const site = Deno.env.get('KAOID_PUBLIC_URL');
  if (Deno.env.get('KAOID_MAIL_ENABLED') !== 'true' || !key || !from || !site || !site.startsWith('https://')) {
    return new Response('Email not configured', {status:503});
  }
  const base = Deno.env.get('SUPABASE_URL')!;
  const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  async function rpc(name: string, body: object = {}) {
    const r = await fetch(`${base}/rest/v1/rpc/${name}`, {method:'POST',headers:{apikey:service,Authorization:`Bearer ${service}`,'Content-Type':'application/json'},body:JSON.stringify(body),signal:AbortSignal.timeout(10000)});
    if (!r.ok) throw new Error('RPC failed');
    return await r.json();
  }
  let accepted = 0;
  try {
    for (let i=0;i<5;i++) {
      const job = await rpc('claim_mail_r10a');
      if (!job) break;
      let success=false; let provider: string|null=null;
      try {
        const r=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${key}`,'Content-Type':'application/json','Idempotency-Key':`kaoid-notice-${job.id}`},body:JSON.stringify({from,to:[job.email],subject:'Kao ID — notification',text:`มีการแจ้งเตือนใหม่ใน Kao ID\nYou have a new Kao ID notification.\nKao ID に新しいお知らせがあります。\n您有一条新的 Kao ID 通知。\nKao ID အကြောင်းကြားချက်အသစ် ရှိသည်။\nມີການແຈ້ງເຕືອນໃໝ່ໃນ Kao ID\nBạn có thông báo Kao ID mới.\n\n${site}\n\nSign in to view details. This email does not contain identity documents.`}),signal:AbortSignal.timeout(15000)});
        success=r.ok;
        if(success){provider=(await r.json()).id??null;accepted++;}
      } catch { success=false; }
      await rpc('finish_mail_r10a',{p_id:job.id,p_token:job.token,p_success:success,p_provider:provider});
    }
    return Response.json({accepted});
  } catch { return new Response('Worker failed; queued items remain retryable', {status:500}); }
});
