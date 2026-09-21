-- Project Afyon 049 — Koyun Atlatma canlı spiker
-- Every sheep gets a named commentary beat; the eventual winner gets a late-race buildup.

CREATE OR REPLACE FUNCTION private.create_special_match_plan(p_match_id text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare
  m public.matches%rowtype;
  i integer;
  minute integer;
  reveal_seconds integer;
  v_side text;
  v_total_goals integer;
  v_home integer:=0;
  v_away integer:=0;
  v_ridvan boolean:=false;
  v_ptero boolean:=false;
  v_backward boolean:=false;
  v_rule boolean:=false;
  v_object boolean:=false;
  v_hesitation boolean:=false;
  v_return boolean:=false;
  v_shepherd_first boolean:=false;
  v_chain boolean:=false;
  v_opposite boolean:=false;
  v_jump boolean:=false;
  v_jury boolean:=false;
  v_graze boolean:=false;
  v_arch boolean:=false;
  v_winner text;
  v_goal record;
begin
  select * into m
  from public.matches
  where id=p_match_id
  for update;

  if not found or m.sport<>'special' or m.status<>'scheduled' or m.kickoff_at>now() then return; end if;

  delete from public.match_events where match_id=m.id;

  if m.special_key='AROG_FINAL' then
    v_total_goals:=4+floor(random()*5)::integer;

    for i in 1..v_total_goals loop
      minute:=4+floor(random()*84)::integer;
      v_side:=case when random()<0.5 then 'home' else 'away' end;
      if v_side='home' then v_home:=v_home+1; else v_away:=v_away+1; end if;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'goal',v_side,jsonb_build_object('importance','goal'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end loop;

    v_ridvan:=random()<0.5;
    v_ptero:=random()<0.5;
    v_backward:=random()<0.5;
    v_rule:=random()<0.5;
    v_object:=random()<0.5;

    if v_ridvan then
      minute:=24+floor(random()*50)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'special_ridvan','neutral',jsonb_build_object('text','Rıdvan Dilmen teknik alana doğru ilerliyor. AFMB hangi sıfatla geldiğini tespit edemedi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_ptero then
      minute:=18+floor(random()*62)::integer;
      v_side:=case when random()<0.5 then 'home' else 'away' end;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'special_pteranodon',v_side,jsonb_build_object('text','Bir oyuncu Pteranodon tarafından müsabaka alanından geçici olarak uzaklaştırıldı.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_backward then
      select e.minute,e.side into v_goal
      from public.match_events e
      where e.match_id=m.id and e.event_type='goal'
      order by random()
      limit 1;
      if found then
        reveal_seconds:=greatest(1,round((v_goal.minute::numeric/90.0)*m.duration_seconds)::integer);
        insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
        values(m.id,v_goal.minute,'special_backward_goal',v_goal.side,jsonb_build_object('text','GERİ KALMIŞ MEDENİYETLER ADINA!'),m.kickoff_at+make_interval(secs=>reveal_seconds));
      end if;
    end if;

    if v_rule then
      minute:=12+floor(random()*65)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'special_new_rule','neutral',jsonb_build_object('text','Arif yeni bir futbol kuralı açıkladı. Yazılı metne ulaşılamadı.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_object then
      minute:=9+floor(random()*72)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'special_foreign_object','neutral',jsonb_build_object('text','Futbol topu dışında bir cisim oyuna dahil oldu. Hakem devam kararı verdi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    update public.matches
    set special_outcomes=jsonb_build_object(
      'SP_RIDVAN',v_ridvan,
      'SP_PTERANODON',v_ptero,
      'SP_BACKWARD_GOAL',v_backward,
      'SP_NEW_RULE',v_rule,
      'SP_FOREIGN_OBJECT',v_object
    )
    where id=m.id;

  elsif m.special_key='SHEEP_JUMP' then
    v_winner:=(array['KINALI','KARABAS','PAMUK','REIS','FISTIK','MOR'])[1+floor(random()*6)::integer];
    v_hesitation:=random()<0.5;
    v_return:=random()<0.5;
    v_shepherd_first:=random()<0.5;
    v_chain:=random()<0.5;
    v_opposite:=random()<0.5;
    v_jump:=random()<0.5;
    v_jury:=random()<0.5;
    v_graze:=random()<0.5;
    v_arch:=random()<0.5;

    insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
    select
      m.id,
      x.minute,
      'sheep_commentary',
      'neutral',
      jsonb_build_object('sheep',x.sheep,'text',x.line),
      m.kickoff_at+make_interval(secs=>greatest(1,round((x.minute::numeric/90.0)*m.duration_seconds)::integer))
    from (values
      (5,'KINALI','Kınalı geliyor! Kıyıya kadar indi, suya baktı, bir adım attı... AFMB ilk ciddi hamleyi kayda geçiriyor.'),
      (14,'KARABAS','Karabaş geliyor! Kalabalığın arasından sıyrıldı, tempo yaptı. Çoban arkadan talimat yağdırıyor.'),
      (23,'PAMUK','Pamuk geliyor! Acele etmiyor ama çizgisini hiç bozmuyor. Sessiz sakin parkurun içine girdi.'),
      (32,'REIS','Reis geliyor! İsminin ağırlığıyla suyun başına geldi. Tribünde nedensiz bir ciddiyet oluştu.'),
      (41,'FISTIK','Fıstık geliyor! Küçük adımlar hızlandı, kıyıda beklemiyor. AFMB kronometreyi tekrar kontrol etti.'),
      (50,'MOR','Mor Koyun geliyor! Neden mor olduğu yine açıklanmadı. Parkur devam ediyor, sorular daha sonra.')
    ) as x(minute,sheep,line);

    minute:=68;
    reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
    insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
    values(
      m.id,minute,'sheep_commentary','neutral',
      jsonb_build_object(
        'sheep',v_winner,
        'text',
        case v_winner
          when 'KINALI' then 'Kınalı öne çıktı! Sudan çıkış çizgisine doğru güçlü geliyor. Kınalı bugün bu işi ciddiye almış!'
          when 'KARABAS' then 'Karabaş öne çıktı! Su sıçrıyor, tempo yükseliyor. Karabaş karşı kıyıya gözünü dikti!'
          when 'PAMUK' then 'Pamuk öne çıktı! Sessiz başladığı turda şimdi bütün sürüyü arkasına aldı. Pamuk geliyor!'
          when 'REIS' then 'Reis öne çıktı! Adına yakışır biçimde grubun başına geçti. Çoban bile bir an kenara çekildi!'
          when 'FISTIK' then 'Fıstık öne çıktı! Küçük adımlar bitti, resmen depar atıyor. Fıstık çok güçlü geliyor!'
          else 'Mor Koyun öne çıktı! Tribün hem yarışa hem renge şaşırmış durumda. Mor Koyun geliyor!'
        end
      ),
      m.kickoff_at+make_interval(secs=>reveal_seconds)
    );

    minute:=78;
    reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
    insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
    values(
      m.id,minute,'sheep_commentary','neutral',
      jsonb_build_object(
        'sheep',v_winner,
        'text',
        (case v_winner
          when 'KINALI' then 'Kınalı'
          when 'KARABAS' then 'Karabaş'
          when 'PAMUK' then 'Pamuk'
          when 'REIS' then 'Reis'
          when 'FISTIK' then 'Fıstık'
          else 'Mor Koyun'
        end)||' son metrelerde! Karşı kıyı çok yakın... AFMB sonucu açıklamak için mührü hazırlıyor!'
      ),
      m.kickoff_at+make_interval(secs=>reveal_seconds)
    );

    if v_hesitation then
      minute:=10+floor(random()*55)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_hesitation','neutral',jsonb_build_object('text','Bir koyun kıyıda en az 5 saniye bekleyerek hayat tercihlerini değerlendirdi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_return then
      minute:=20+floor(random()*50)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_water_return','neutral',jsonb_build_object('text','Bir koyun suya girdikten sonra fikrini değiştirip kıyıya geri döndü.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_shepherd_first then
      minute:=8+floor(random()*45)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_shepherd_first','neutral',jsonb_build_object('text','Çoban karşı kıyıya ulaştı. Koyun hâlâ prosedürü inceliyor.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_chain then
      minute:=18+floor(random()*48)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_chain_jump','neutral',jsonb_build_object('text','Bir koyunun ardından en az üç koyun peş peşe suya atladı.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_opposite then
      minute:=15+floor(random()*52)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_opposite_way','neutral',jsonb_build_object('text','Bir koyun sürünün ters yönüne gidiyor. AFMB bunun taktik olup olmadığını araştırıyor.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_jump then
      minute:=12+floor(random()*58)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_dramatic_jump','neutral',jsonb_build_object('text','Belirgin derecede gösterişli bir sıçrayış kayıtlara geçti.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_jury then
      minute:=58+floor(random()*22)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_jury_split','neutral',jsonb_build_object('text','Hakem heyeti puanlama konusunda anlaşamadı. Tutanak iki nüsha düzenlendi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_graze then
      minute:=7+floor(random()*57)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_grazing','neutral',jsonb_build_object('text','Bir koyun yarışmayı bırakıp otlamaya yöneldi.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    if v_arch then
      minute:=25+floor(random()*43)::integer;
      reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
      insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
      values(m.id,minute,'sheep_archaeology','neutral',jsonb_build_object('text','Denizli arkeoloji heyeti olaya gereğinden fazla ilgi gösteriyor.'),m.kickoff_at+make_interval(secs=>reveal_seconds));
    end if;

    minute:=84;
    reveal_seconds:=greatest(1,round((minute::numeric/90.0)*m.duration_seconds)::integer);
    insert into public.match_events(match_id,minute,event_type,side,payload,visible_at)
    values(m.id,minute,'sheep_winner','neutral',jsonb_build_object('winner',v_winner,'text','Sudan Koyun Atlatma sonucu kesinleşti.'),m.kickoff_at+make_interval(secs=>reveal_seconds));

    update public.matches
    set special_outcomes=jsonb_build_object(
      'SP_SHEEP_WINNER',v_winner,
      'SP_SHEEP_HESITATION',v_hesitation,
      'SP_SHEEP_RETURN',v_return,
      'SP_SHEPHERD_FIRST',v_shepherd_first,
      'SP_SHEEP_CHAIN',v_chain,
      'SP_SHEEP_OPPOSITE',v_opposite,
      'SP_SHEEP_DRAMATIC',v_jump,
      'SP_SHEEP_JURY',v_jury,
      'SP_SHEEP_GRAZE',v_graze,
      'SP_SHEEP_ARCH',v_arch
    )
    where id=m.id;
  else
    return;
  end if;

  insert into private.match_plans(match_id,final_home_goals,final_away_goals)
  values(m.id,v_home,v_away)
  on conflict(match_id) do update
  set final_home_goals=excluded.final_home_goals,
      final_away_goals=excluded.final_away_goals;

  update public.match_markets set locked=true where match_id=m.id;
  update public.matches set status='live',started_at=m.kickoff_at where id=m.id;
end;
$function$

