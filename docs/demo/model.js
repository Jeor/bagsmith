import {items,categories,defaults} from './data.js';
export function validate(input={}) {
 const state={...defaults};
 const choices={layout:['compact','split','standard'],view:['icons','list'],group:['section','all','bag'],sort:['quality','name','newest','off'],scenario:['everyday','full','long','empty'],skin:['modern','classic'],tab:['All','Gear','Consumables','Trade Goods','Quest','Junk','Bank']};
 for(const [key,allowed] of Object.entries(choices)) if(allowed.includes(input[key])) state[key]=input[key];
 for(const key of ['merge','count','vendor','auction','drawer']) if(typeof input[key]==='boolean') state[key]=input[key];
 for(const [key,min,max] of [['size',32,64],['gap',4,20],['opacity',65,100],['width',500,1400],['height',360,1000]]) if(Number.isFinite(input[key])) state[key]=Math.min(max,Math.max(min,input[key]));
 return state;
}
export function inventory(state,query='',rare=false) {
 let result=state.scenario==='empty'?[]:items.map(i=>({...i}));
 if(state.scenario==='full') result=Array.from({length:3},(_,n)=>items.map(i=>({...i,id:i.id+n*100,recent:n===0&&i.recent}))).flat();
 if(state.tab==='Bank') result=result.filter(i=>i.id%3===0).map(i=>({...i,count:i.count*2}));
 else if(state.tab==='Junk') result=result.filter(i=>i.quality===0);
 else if(state.tab!=='All') result=result.filter(i=>i.category===state.tab);
 result=result.filter(i=>(!rare||i.quality>=2)&&`${i.name} ${i.category}`.toLowerCase().includes(query.toLowerCase()));
 if(state.merge) {const merged=new Map(); for(const item of result){const key=`${item.category}:${item.name}${state.group==='bag'?':'+item.bag:''}`; if(merged.has(key)) merged.get(key).count+=item.count;else merged.set(key,{...item});}result=[...merged.values()];}
 if(state.sort==='name') result.sort((a,b)=>a.name.localeCompare(b.name));
 if(state.sort==='quality') result.sort((a,b)=>b.quality-a.quality);
 if(state.sort==='newest') result.sort((a,b)=>b.id-a.id);
 return result;
}
export function groups(list,state) {
 if(state.group==='all') return [{name:'All Items',items:list}];
 const names=state.group==='bag'?['Backpack','Linen Bag','Woolen Bag','Traveler’s Bag']:categories;
 return names.map((name,index)=>({name:state.scenario==='long'&&name==='Consumables'?'Potions, Food & Adventure Supplies':name,items:list.filter(i=>state.group==='bag'?i.bag===index+1:i.category===name)})).filter(g=>g.items.length);
}
