import {test} from 'node:test';
import assert from 'node:assert/strict';
import {validate,inventory,groups} from './model.js';
test('untrusted share settings are bounded and enums validated',()=>{const s=validate({size:999,height:-100,layout:'evil',vendor:'false'});assert.equal(s.size,64);assert.equal(s.height,360);assert.equal(s.layout,'compact');assert.equal(s.vendor,true);});
test('merging preserves item quantity and vendor total',()=>{const s=validate({merge:false});const a=inventory(s),b=inventory({...s,merge:true});assert.ok(a.length>b.length);for(const total of [x=>x.count,x=>x.count*x.vendor])assert.equal(a.reduce((n,i)=>n+total(i),0),b.reduce((n,i)=>n+total(i),0));});
test('search and rarity filter compose with tabs',()=>{const a=inventory(validate({tab:'Gear'}),'bronze',true);assert.equal(a.length,1);assert.equal(a[0].name,'Bronze Band');assert.equal(inventory(validate({tab:'Gear'}),'copper',true).length,0);});
test('by bag grouping never loses an item',()=>{const s=validate({group:'bag',scenario:'full'}),list=inventory(s);assert.equal(groups(list,s).reduce((n,g)=>n+g.items.length,0),list.length);});
test('empty and long scenarios exercise meaningful edge states',()=>{assert.equal(inventory(validate({scenario:'empty'})).length,0);const s=validate({scenario:'long'});assert.ok(groups(inventory(s),s).some(g=>g.name.length>30));});
