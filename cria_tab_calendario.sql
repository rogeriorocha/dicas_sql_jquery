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
    dat_post_util    date
);

alter table calendario
    owner to postgres;

