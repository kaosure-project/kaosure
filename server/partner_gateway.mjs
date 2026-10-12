// Server-only integration seam. No provider adapters are bundled or enabled.
// Registry entries and secrets must come from trusted deployment configuration,
// never the incoming request or the browser. An adapter is specific to a provider.
import { createHash } from 'node:crypto';

export class PartnerGateway {
  constructor({ adapters, receive, maxBodyBytes = 262144 }) {
    this.adapters = new Map(adapters);
    this.receive = receive;
    this.maxBodyBytes = maxBodyBytes;
  }
  async accept({ binding, rawBody, headers }) {
    if (!binding || !['sandbox','live'].includes(binding.environment)) throw new Error('invalid_binding');
    // binding is resolved by the server, not accepted from request JSON.
    const adapter = this.adapters.get(`${binding.code}:${binding.environment}`);
    if (!adapter) throw new Error('adapter_unavailable');
    if (!(rawBody instanceof Uint8Array) || rawBody.byteLength > this.maxBodyBytes) throw new Error('invalid_body');
    // Must authenticate the ORIGINAL bytes, enforce provider replay/freshness rules,
    // validate merchant/account identity, schema, amount/currency, and event type.
    // It must throw on unsupported or unverifiable events; no generic fallback.
    const event = await adapter.verifyAndNormalize({ rawBody, headers, binding });
    if (!event || typeof event.id !== 'string' || !event.id.length || event.id.length>200 ||
        !(binding.kind === 'shipping' ? ['quote','shipment','tracking','cancel_shipment'] : ['balance','payment','refund','payout','topup']).includes(event.capability)) throw new Error('invalid_event');
    // DB rechecks Owner authorization, current readiness/expiry and environment.
    // Exact retries return the same receipt. Conflicting event content is rejected.
    // Receipt means recorded, NOT settled, credited or paid.
    return this.receive({
      p_id: binding.id, p_environment: binding.environment,
      p_event: event.id, p_capability: event.capability,
      p_hash: createHash('sha256').update(rawBody).digest('hex'),
    });
  }
}
