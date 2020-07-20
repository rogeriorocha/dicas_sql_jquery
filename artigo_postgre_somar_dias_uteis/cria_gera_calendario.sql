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

   data_de := to_date('2020-01-01', 'YYYY-MM-DD');
   data_ate := to_date('2020-12-31', 'YYYY-MM-DD');

   num_dia := 1;
   num_dia_util := 0;
   dat_ant_util := null;

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


  RETURN rowsAffected;
END;
$$;

alter function gera_calendario() owner to postgres;
