create or replace function adiciona_dias_uteis(var_data date, dias integer, var_cidade_id integer) returns date
stable
  language plpgsql
as
$$
DECLARE
  intervalo interval := '1 day';
  contador integer = 0;
BEGIN
	WHILE (contador < dias) dias LOOP

		/**
		 *Acrescenta o intervalo de um dia a data
		 */
		var_data :=  var_data + intervalo;

		IF  not ediautil(var_data, var_cidade_id) THEN
			CONTINUE;
		END IF;

		/**
		 *Acrescenta um dia útil ao contador.
		 */
		contador := contador + 1;

		/**
		 *Exibe os valores das variaveis, durante o loop.
		 *Caso queira verificar os valores descomente os comandos "RAISE NOTICE"
		 */


		--RAISE NOTICE 'var_data:%', var_data;
		--RAISE NOTICE 'contador: %', contador;
		--RAISE NOTICE 'DOW dia da semana valor numerico:%', EXTRACT(DOW FROM var_data);
		--RAISE NOTICE '';
	END LOOP;
	RETURN var_data;
END
$$;


create or replace function eDiaUtil(var_data date, var_cidade_id integer) returns boolean
stable
    language plpgsql
as
$eDiaUtil$
DECLARE
  verifica_cidade boolean;
BEGIN

	SELECT INTO verifica_cidade
	EXISTS
	(
		SELECT cidade_nome FROM tab_cidades WHERE cidade_id = var_cidade_id
	);
	/**
	*Verifica se foi passado o parâmetro com a identificação da cidade.
	*/
	IF(var_cidade_id IS NULL ) THEN
		RAISE EXCEPTION 'Preencha o código da cidade.';
	/**
	*Verifica se a cidade esta cadastrada na tabela tab_cidades.
	*/
	ELSIF(verifica_cidade = FALSE) THEN
		RAISE EXCEPTION
		'
		Não existe código para esta cidade.
		Verifique o código correto na tabela tab_cidades.
		Caso não exista, você deve incluí-lo.
		';
	END IF;
		/**
		 *Verifica se a data é sábado ou domingo.
		 *Caso seja reinicia o loop através do comando "CONTINUE".
		 *Caso contrário executará a próxima verificação, ou seja verificará se o dia é feriado federal
		 */
		IF ((EXTRACT(DOW FROM var_data) = 0) OR (EXTRACT(DOW FROM var_data) = 6)) THEN
		    return false;
		END IF;

		/**
		 *Verifica se a data é feriado federal.
		 *Caso seja reinicia o loop através do comando "CONTINUE".
		 *Caso contrário executará a próxima verificação, ou seja verificará se o dia é feriado religioso
		 */
		IF
		(
			EXISTS
			(
				SELECT feriado_federal FROM tab_feriado_federal
				WHERE to_char(feriado_federal, 'mm-dd') = to_char(var_data, 'mm-dd')
			) = TRUE
		) THEN
			return false;
		END IF;

		/**
		 *Verifica se o feriado é pascoa, carnaval, sexta-feira santa e corpos Corpus Christi.
		 *Caso seja reinicia o loop através do comando "CONTINUE".
		 *Caso contrário executará a próxima instrução.
		 */
		IF
		(
			EXISTS
			(
				SELECT data FROM feriados_moveis(EXTRACT(YEAR FROM var_data) :: integer)
				WHERE data=  var_data
			) = TRUE
		) THEN
			return false;
		END IF;


		/**
		 *Verifica feriado estadual.
		 */
		IF(
			EXISTS
			(
				SELECT feriado_estadual
				FROM tab_feriado_estadual
				JOIN tab_cidades
				ON tab_feriado_estadual.sigla_estado = tab_cidades.sigla_estado
				WHERE cidade_id =  var_cidade_id AND
				to_char(feriado_estadual, 'mm-dd') = to_char(var_data, 'mm-dd')
			) = TRUE
		) THEN
			return false;
		END IF;

		/**
		 *Verifica feriado municipal
		 */
		IF(
			EXISTS
			(
				SELECT feriado_municipal
				FROM tab_feriado_municipal
				WHERE cidade_id =  var_cidade_id AND
				to_char(feriado_municipal, 'mm-dd') = to_char(var_data, 'mm-dd')
			) = TRUE
		) THEN
			return false;
		END IF;

		/**
		 *Acrescenta um dia útil ao contador.
		 */

		/**
		 *Exibe os valores das variaveis, durante o loop.
		 *Caso queira verificar os valores descomente os comandos "RAISE NOTICE"
		 */

		--RAISE NOTICE 'var_data:%', var_data;
		--RAISE NOTICE 'contador: %', contador;
		--RAISE NOTICE 'DOW dia da semana valor numerico:%', EXTRACT(DOW FROM var_data);
		--RAISE NOTICE '';

	RETURN true;
END
$eDiaUtil$;
