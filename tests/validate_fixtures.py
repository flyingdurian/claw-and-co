#!/usr/bin/env python3
"""External preflight for Claw & Co. authored content; requires jsonschema."""
from collections import Counter
from pathlib import Path
import json
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]
def read(p):
    return json.loads((ROOT / p).read_text(encoding='utf-8'))

def check(condition, message):
    if not condition:
        raise AssertionError(message)

def validate_schema(schema_file, data_file):
    schema = read('schemas/' + schema_file)
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(read('data/' + data_file)), key=lambda e: list(map(str, e.path)))
    if errors:
        raise AssertionError(f'{data_file}: ' + ' | '.join(f'{list(e.path)} {e.message}' for e in errors))


def main():
    validate_schema('items.schema.json','items.stage1.json')
    validate_schema('machine_types.schema.json','machine_types.stage1.json')
    validate_schema('stage.schema.json','stage_01.json')
    catalog = read('data/items.stage1.json')['items']
    types = read('data/machine_types.stage1.json')['machine_types']
    stage = read('data/stage_01.json')
    item_ids=[i['id'] for i in catalog]; type_ids=[t['id'] for t in types]
    check(len(item_ids)==len(set(item_ids)), 'duplicate item SKU id')
    check(len(type_ids)==len(set(type_ids)), 'duplicate machine type id')
    imap={i['id']:i for i in catalog}; tmap={t['id']:t for t in types}
    check({t['kind'] for t in types} == {'plush_3_prong','ufo_2_prong','barber_cut'},'need all three machine kinds')
    check(stage['tick_hz']==60,'must be 60 Hz')
    check(stage['cart']=={'supply_slots':4,'prize_slots':2,'bulk_cradle_slots':1},'cart config mismatch')
    check(len(stage['cabinet_instances'])==4,'Stage 1 requires four cabinets')
    machine_ids=[c['machine_id'] for c in stage['cabinet_instances']]
    check(len(machine_ids)==len(set(machine_ids)),'duplicate cabinet instance ID')
    cabinets={c['machine_id']:c for c in stage['cabinet_instances']}
    check(Counter(c['access_policy'] for c in cabinets.values()) == {'walk_up':2,'reserved_choice':2},'access policy split incorrect')
    all_cassettes=[]
    all_stock=[]
    provenance={}
    def track(uid, item_id, location):
        check(item_id in imap, f'unknown item {item_id} at {location}')
        check(uid not in provenance, f'physical instance {uid} has duplicate owners {provenance.get(uid)} / {location}')
        provenance[uid]=location
        all_stock.append((uid,item_id,location))
    def check_cassette(cassette, owner, machine_type=None):
        uid=cassette['cassette_instance_id']; item_id=cassette['cassette_item_id']
        check(imap[item_id]['kind']=='cassette',f'{uid} is not a cassette')
        check(uid not in all_cassettes,f'duplicate cassette {uid}')
        all_cassettes.append(uid)
        track(uid,item_id,owner)
        cformat=imap[item_id]['cassette_format']
        check(len(cassette['contents'])<=imap[item_id]['capacity_units'],f'cassette {uid} exceeds capacity')
        if machine_type:
            check(cformat in machine_type['cassette_formats'],f'cassette {uid} incompatible with machine')
        for p in cassette['contents']:
            track(p['instance_id'],p['item_id'],f'{owner}/cassette:{uid}')
            check(imap[p['item_id']]['kind'] in ('plush','figure'),f'cassette {uid} contains non-prize')
            if machine_type:
                check(imap[p['item_id']]['kind'] in machine_type['accepted_prize_kinds'],f'prize {p} incompatible with machine')
    for c in cabinets.values():
        check(c['machine_type_id'] in tmap,f'unknown machine type {c["machine_type_id"]}')
        check_cassette(c['loaded_cassette'],f'cabinet:{c["machine_id"]}',tmap[c['machine_type_id']])
    inv=stage['initial_inventory']
    for cassette in inv['machine_bay']:
        check_cassette(cassette,'machine_bay')
    for area in ['workshop','trade_counter']:
        for item in inv[area]:track(item['instance_id'],item['item_id'],area)
    account_ids=[c['customer_id'] for c in stage['customer_accounts']]
    check(len(account_ids)==len(set(account_ids)),'duplicate customer')
    accounts=set(account_ids)
    seen_cards=[c['card_instance_id'] for c in stage['customer_accounts'] if c['card_instance_id']]
    check(len(seen_cards)==len(set(seen_cards)),'duplicate card account ID')
    for owned in inv['customer_owned']:
        check(owned['customer_id'] in accounts,'unknown customer owns stock')
        for item in owned['items']:track(item['instance_id'],item['item_id'],'customer:'+owned['customer_id'])
    offers={o['offer_id']:o for o in stage['offers']}
    check(len(offers)==len(stage['offers']),'duplicate offer id')
    for offer in offers.values():
        check(offer['card_item_id'] in imap,'offer unknown SKU')
        check(imap[offer['card_item_id']]['kind']=='card','offer SKU not card')
        check(imap[offer['card_item_id']]['card_mode']==('physical_starter' if offer['kind']=='starter_card' else 'topup_service'),'offer kind not consistent with card SKU')
        check(imap[offer['card_item_id']]['credit_units']==offer['credit_units'],'offer credit_units differ from catalog')
    visits=[]; all_sessions={s['session_id']:s for s in stage['sessions']}
    check(len(all_sessions)==len(stage['sessions']),'duplicate session ID')
    last_wave=-1
    for wave in stage['waves']:
        check(wave['start_tick']>last_wave,'wave start ticks must strictly increase')
        last_wave=wave['start_tick']
        for v in wave['visits']:
            check(v['customer_id'] in accounts,f'unknown customer {v["customer_id"]}')
            check(wave['start_tick']<=v['arrival_tick']<stage['duration_ticks'],'visit outside wave/stage')
            check(v['arrival_tick']<v['deadline_tick']<=stage['duration_ticks'],'visit invalid deadline')
            visits.append(v)
            for step in v['steps']:
                act=step['action']
                if act=='purchase_card':
                    check(step['offer_id'] in offers,'unknown offer')
                    if 'intended_session_id' in step:
                        check(step['intended_session_id'] in all_sessions,'unknown pre-purchase intent session')
                        check(all_sessions[step['intended_session_id']]['customer_id']==v['customer_id'],'pre-purchase intent bound to wrong customer')
                        check(any(x['action']=='admit_session' and x['session_id']==step['intended_session_id'] for x in v['steps']), 'pre-purchase intent not matched by visit session')
                elif act=='admit_session':
                    check(step['session_id'] in all_sessions,'unknown session')
                    check(all_sessions[step['session_id']]['customer_id']==v['customer_id'],'session wrong customer')
                elif act=='trade_up':check(any(r['rule_id']==step['rule_id'] for r in stage['tradeup_rules']),'unknown trade rule')
                elif act=='gift_wrap':
                    uid=step['prize_instance_id']
                    check(provenance.get(uid)=='customer:'+v['customer_id'],'gift-wrap prize not owned by customer')
                    check(provenance.get(step['gift_box_id'])=='workshop','gift box not workshop-owned')
                    check(provenance.get(step['ribbon_id'])=='workshop','ribbon not workshop-owned')
                elif act=='request_staff_reset':check(step['machine_id'] in cabinets,'unknown cabinet reset')
    check(len(visits)==8,'Stage 1 requires eight service visits')
    check(len({v['visit_id'] for v in visits})==8,'duplicate visit ID')
    check(len(stage['waves'])==3,'Stage 1 requires three waves')
    check(sum(w['spectator_count'] for w in stage['waves'])==4,'Stage 1 requires four spectators')
    for sess in all_sessions.values():
        check(sess['machine_id'] in cabinets,'session unknown machine')
        c=cabinets[sess['machine_id']]
        stockuids=[p['instance_id'] for p in c['loaded_cassette']['contents']]
        stockuids += [p['instance_id'] for cart in inv['machine_bay'] for p in cart['contents']]
        check(sess['requested_prize_instance_id'] in stockuids,'session requested prize absent from initial stock or incoming cassette')
        check([a['attempt_index'] for a in sess['attempts']]==list(range(1,len(sess['attempts'])+1)),'attempt indexes must be sequential')
        check(sum(a['result']=='win' for a in sess['attempts'])<=1,'more than one win per session')
        check(all(a['result']!='win' for a in sess['attempts'][:-1]),'win cannot be followed by attempts')
    referenced_sessions=[step['session_id'] for v in visits for step in v['steps'] if step['action']=='admit_session']
    check(Counter(referenced_sessions)==Counter(all_sessions.keys()),'every session must be admitted exactly once')
    check(len({j['job_id'] for j in stage['staff_jobs']})==len(stage['staff_jobs']),'duplicate staff job')
    for job in stage['staff_jobs']:
        check(job['machine_id'] in cabinets,'job for unknown cabinet')
        check(job['available_tick']<job['deadline_tick']<=stage['duration_ticks'],'invalid staff job timing')
        if job['kind']=='restock':
            uid=job['cassette_instance_id']
            check(uid in all_cassettes and provenance[uid]=='machine_bay','restock cassette not in machine bay')
            cass=next(c for c in inv['machine_bay'] if c['cassette_instance_id']==uid)
            check(imap[cass['cassette_item_id']]['cassette_format'] in tmap[cabinets[job['machine_id']]['machine_type_id']]['cassette_formats'],'restock cassette incompatible')
        else:
            check(any(s['machine_id']==job['machine_id'] and any(a['result']=='stuck' for a in s['attempts']) for s in all_sessions.values()),'reset job with no scripted obstruction')
    rules={r['rule_id']:r for r in stage['tradeup_rules']}
    check(len(rules)==len(stage['tradeup_rules']),'duplicate trade rules')
    for r in rules.values():
        check(r['input_item_id'] in imap and r['output_item_id'] in imap,'trade rule unknown SKU')
        check(provenance.get(r['output_instance_id'])=='trade_counter','trade-up output not at trade counter')
        check(next(i for i in all_stock if i[0]==r['output_instance_id'])[1]==r['output_item_id'],'trade-up output wrong SKU')
    production_ids=set()
    for j in stage['production_jobs']:
        check(j['job_id'] not in production_ids,'duplicate production job')
        production_ids.add(j['job_id'])
        check(j['available_tick']+j['duration_ticks'] <= stage['duration_ticks'],'production completion out of bounds')
        for part in j['input_items']:
            check(provenance.get(part['instance_id']) == ('machine_bay' if j['kind']=='prepare_cassette' else 'workshop'), 'production input has invalid stock owner')
            check(next(t for uid,t,loc in all_stock if uid==part['instance_id'])==part['item_id'],'production input sku mismatch')
        if j['kind']=='charge_cards':
            check(any(i['instance_id']==j['output_item']['instance_id'] and i['item_id']==j['output_item']['item_id'] for i in j['input_items']),
                'charging should retain physical card UID; only charge status changes')
    thresholds=stage['scoring']['thresholds']
    check([r['stars'] for r in thresholds]==[1,2,3],'stars must be 1,2,3')
    check(all(a['minimum_score']<b['minimum_score'] for a,b in zip(thresholds,thresholds[1:])),'star threshold monotonicity')
    print(f'PASS: 3 JSON schemas, {len(catalog)} SKUs, {len(types)} machine types, {len(cabinets)} cabinets, '
          f'{len(visits)} visits, {len(all_sessions)} sessions, {len(all_stock)} uniquely owned item instances, '
          f'{len(stage["staff_jobs"])} staff jobs, {len(stage["production_jobs"])} production jobs')

if __name__ == '__main__':
    main()
