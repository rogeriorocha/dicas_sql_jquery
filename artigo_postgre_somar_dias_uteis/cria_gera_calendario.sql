

create table ano_mes
(
    ano               integer not null,
    mes               integer not null,
    qtd_dia           integer,
    qtd_dia_util      integer,
    dat_prim_dia      date,
    dat_prim_dia_util date,
    dat_ult_dia       date,
    dat_ult_dia_util  date,
    ano_mes           integer,
    ano_prox          integer,
    mes_prox          integer,
    ano_mes_prox      integer,
    ano_ant           integer,
    mes_ant           integer,
    ano_mes_ant       integer,
    num_ult_dia_util  integer,
    num_prim_dia_util integer,
    constraint ano_mes_pk
        primary key (ano, mes)
);

alter table ano_mes
    owner to postgres;
    

create table calendario
(
    data             date              not null
        constraint calendario_pk
            primary key,
    dia              integer           not null,
    mes              integer           not null,
    ano              integer           not null,
    flg_dia_util     varchar default 1 not null,
    flg_fim_sem      varchar default 1,
    num_seq_dia      integer           not null,
    dat_ant          date,
    dat_post         date,
    num_seq_dia_util integer,
    num_dia_sem      integer,
    dat_ant_util     date,
    dat_post_util    date,
    num_sem          integer
);

alter table calendario
    owner to postgres;




create or replace function gera_calendario() returns integer
    language plpgsql
as
$$
declare
   data_de date;
   data_ate date;

   rowsAffected integer;
   eFinalDeSemana varchar(1);
   eDiaUtil varchar(1);
   num_dia integer;
   num_dia_util integer;

   _dat_post_util date;
   dat_ant_util date;

   v_calendario RECORD;
BEGIN
   rowsAffected := 0;

   data_de := to_date('1991-01-01', 'YYYY-MM-DD');
   data_ate := to_date('2080-12-31', 'YYYY-MM-DD');

   num_dia := 1;
   num_dia_util := 0;
   dat_ant_util := null;

   delete from ano_mes;

   WHILE data_de <= data_ate LOOP
       rowsAffected := rowsAffected + 1;

       IF ((EXTRACT(DOW FROM data_de) = 0) OR (EXTRACT(DOW FROM data_de) = 6)) THEN
           eFinalDeSemana := 'S';
           eDiaUtil := 'N';
        else
           eFinalDeSemana := 'N';
           if ediautil(data_de, 3) then
              eDiaUtil := 'S';
           else
              eDiaUtil := 'N';
           end if;
       end if;

       raise notice 'Data: %, FDS: %, DIAUTIL: % ' , data_de, eFinalDeSemana, eDiaUtil;

       if (eDiaUtil = 'S') then
          num_dia_util := num_dia_util + 1;
       end if;

       insert into calendario (data,
                               dia, mes, ano,
                               flg_dia_util, flg_fim_sem, num_seq_dia,
                               dat_ant, dat_post, num_seq_dia_util,
                               num_dia_sem
                               ,dat_ant_util, dat_post_util, num_sem
                               )
                        values (data_de,
                                EXTRACT(day from data_de), EXTRACT(month from data_de), EXTRACT(year from data_de),
                                eDiaUtil, eFinalDeSemana, num_dia,
                                data_de - interval '1 day', data_de + interval '1 day',num_dia_util,
                                EXTRACT(DOW FROM data_de),
                                dat_ant_util, null, EXTRACT(week FROM data_de)
                                );
       if (eDiaUtil = 'S') then
           dat_ant_util := data_de;
       end if;

       num_dia := num_dia + 1;
       data_de := data_de + interval '1 day';
   end loop;

   _dat_post_util := null;
   FOR v_calendario IN SELECT data, flg_dia_util FROM calendario order by 1 desc
   LOOP
       update calendario
       set dat_post_util = _dat_post_util
       where data = v_calendario.data;

       if (v_calendario.flg_dia_util = 'S') then
           _dat_post_util := v_calendario.data;
       end if;

   END LOOP;

   --
    insert into ano_mes
    select EXTRACT(year FROM c.data) as ano, EXTRACT(month FROM c.data) as mes, count(*) as qtd_dia
     , sum(case when c.flg_dia_util = 'S' then 1 else 0 end) as qtd_dia_util
     , min(data) as dat_prim_dia
     , min(case when c.flg_dia_util = 'S' then c.data else null end) as dat_prim_dia_util
     , max(data) as dat_ult_dia
     , max(case when c.flg_dia_util = 'S' then c.data else null end) as dat_utl_dia_util
     , (EXTRACT(year FROM c.data) * 100) + EXTRACT(month FROM c.data) as ano_mes

     , (EXTRACT(year FROM min(data) + interval '1 month' ) * 100) + EXTRACT(month FROM min(data) + interval '1 month') as ano_mes_prox
     , EXTRACT(year FROM min(data) + interval '1 month' )  as ano_prox
     , EXTRACT(month FROM min(data) + interval '1 month') as mes_prox

     , (EXTRACT(year FROM min(data) - interval '1 month' ) * 100) + EXTRACT(month FROM min(data) - interval '1 month') as ano_mes_ant
     , EXTRACT(year FROM min(data) - interval '1 month' )  as ano_ant
     , EXTRACT(month FROM min(data) - interval '1 month') as mes_ant

     , EXTRACT(day from max(case when c.flg_dia_util = 'S' then c.data else null end)) as num_ult_dia_util
     , EXTRACT(day from min(case when c.flg_dia_util = 'S' then c.data else null end)) as num_prim_dia_util
    from calendario c
    group by EXTRACT(year FROM c.data), EXTRACT(month FROM c.data);
   --


  RETURN rowsAffected;
END;
$$;


alter function gera_calendario() owner to postgres;
