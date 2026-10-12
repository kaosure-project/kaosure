import {createHash} from 'node:crypto';
// For BALANCE SNAPSHOTS only. Use this instead of recording a generic receipt first.
// Adapter must authenticate original bytes and verify the provider account identity.
export class MemberWalletGateway {
 constructor({adapters,sync}){this.adapters=new Map(adapters);this.sync=sync;}
 async accept({binding,rawBody,headers}){
  if(binding?.kind!=='finance' || !['sandbox','live'].includes(binding.environment))throw new Error('invalid_binding');
  const adapter=this.adapters.get(`${binding.code}:${binding.environment}`);
  if(!adapter)throw new Error('adapter_unavailable');
  if(!(rawBody instanceof Uint8Array) || rawBody.byteLength>262144)throw new Error('invalid_body');
  const e=await adapter.verifyAndNormalizeBalance({rawBody,headers,binding});
  const money=v=>typeof v==='string' && /^(0|[1-9][0-9]{0,17})(\.[0-9]{1,2})?$/.test(v);
  if(!e || e.currency!=='THB' || typeof e.externalRef!=='string' || !e.externalRef.trim() || e.externalRef.length>200 || typeof e.id!=='string' || !e.id.length || e.id.length>200 || typeof e.sequence!=='string' || !/^(0|[1-9][0-9]{0,18})$/.test(e.sequence) || BigInt(e.sequence)>9223372036854775807n || ![e.available,e.held,e.pending].every(money) || typeof e.observedAt!=='string' || !Number.isFinite(Date.parse(e.observedAt)))throw new Error('invalid_snapshot');
  return this.sync({p_partner:binding.id,p_environment:binding.environment,p_external:e.externalRef,p_event:e.id,p_hash:createHash('sha256').update(rawBody).digest('hex'),p_sequence:e.sequence,p_available:e.available,p_held:e.held,p_pending:e.pending,p_observed:e.observedAt});
 }
}
