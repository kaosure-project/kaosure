import test from 'node:test';
import assert from 'node:assert/strict';
import {PartnerGateway} from './partner_gateway.mjs';
const binding={id:'internal-binding',code:'example',environment:'sandbox'};
const body=new TextEncoder().encode('{"id":"evt1"}');
test('unregistered provider or wrong environment cannot fall through',async()=>{
 const g=new PartnerGateway({adapters:[],receive:()=>assert.fail('must not record')});
 await assert.rejects(g.accept({binding,rawBody:body,headers:{}}),/adapter_unavailable/);
});
test('signature verification failure never reaches receipt handler',async()=>{
 const g=new PartnerGateway({adapters:[['example:sandbox',{verifyAndNormalize:()=>{throw new Error('invalid_signature');}}]],receive:()=>assert.fail('must not record')});
 await assert.rejects(g.accept({binding,rawBody:body,headers:{}}),/invalid_signature/);
});
test('verified normalized receipt uses server binding and raw content hash',async()=>{
 let sent;
 const g=new PartnerGateway({adapters:[['example:sandbox',{verifyAndNormalize:async()=>({id:'evt1',capability:'payment',p_id:'attacker'})}]],receive:async p=>{sent=p;return 'receipt';}});
 assert.equal(await g.accept({binding,rawBody:body,headers:{}}),'receipt');
 assert.equal(sent.p_id,binding.id);assert.equal(sent.p_environment,'sandbox');assert.match(sent.p_hash,/^[0-9a-f]{64}$/);
 await assert.rejects(g.accept({binding:{...binding,environment:'live'},rawBody:body,headers:{}}),/adapter_unavailable/);
});
test('unsupported event and oversized body fail closed',async()=>{
 const g=new PartnerGateway({adapters:[['example:sandbox',{verifyAndNormalize:async()=>({id:'evt1',capability:'arbitrary_sql'})}]],receive:()=>assert.fail('must not record')});
 await assert.rejects(g.accept({binding,rawBody:body,headers:{}}),/invalid_event/);
 await assert.rejects(g.accept({binding,rawBody:new Uint8Array(262145),headers:{}}),/invalid_body/);
});
