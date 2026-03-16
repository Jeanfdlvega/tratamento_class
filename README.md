# Serviço OData - Material Packages

Método: /iwbep/if_mgw_appl_srv_runtime~get_entityset

## O que faz
Retorna lista de materiais/pacotes da CDS ZCDS_MM_MATERIAL_PACKAGES com cálculo do campo isBlocked.

## Filtros suportados ($filter)
- MATERIALID   → materialId
- PLANTCODE    → plantCode
- COMPANYCODE  → companyCode

Todos opcionais (mas em alguns cenários o frontend exige MATERIALID + PLANTCODE).

## Paginação
Suporta $top e $skip.

## Lógica do isBlocked
Para cada linha onde isBlocked não é inicial:
1. Converte material para formato interno
2. Chama BAPI_OBJCL_GETDETAIL na classe BLOQINTEGRACAO (001)
3. Se erro 'E' na BAPI → ignora o registro
4. Se tem característica ACACIA = 'X':
   - Verifica se o plantCode está na lista CENTROS
   - Se sim → isBlocked = false
   - Se não → isBlocked = true
5. Se não tem classificação:
   - isBlocked = false se:
     - mstde ≤ hoje
     - mstdv ≤ hoje
     - mstae ≠ '07'
     - mstav = '02'
   - Senão → isBlocked = true

## Fluxo principal
- Pega filtros OData → ranges
- SELECT na CDS com WHERE (campo IS INITIAL OR IN range)
- Loop nas linhas → calcula isBlocked
- Copia resultado para er_entityset

## Sugestões rápidas de melhoria
- Use WHERE dinâmico (string) para melhor performance
- Adicione validação se MATERIALID e PLANTCODE forem obrigatórios:
  IF rl_materialid IS INITIAL OR rl_plantcode IS INITIAL. RETURN. ENDIF.
- Cache da classificação (evitar chamar BAPI em loop para muitos registros)

Exemplo de chamada:
GET .../MaterialPackages?$filter=MATERIALID eq '123456' and PLANTCODE eq '1000'&$top=20
