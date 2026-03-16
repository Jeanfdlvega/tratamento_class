METHOD /iwbep/if_mgw_appl_srv_runtime~get_entityset.

  DATA: rl_materialid  TYPE RANGE OF matnr,
        rl_plantcode   TYPE RANGE OF werks_d,
        rl_companycode TYPE RANGE OF bukrs,
        lt_filter      TYPE /iwbep/t_mgw_select_option,
        lv_where       TYPE string,
        lv_top         TYPE i,
        lv_skip        TYPE i.

  DATA: lt_packages        TYPE TABLE OF zcds_mm_material_packages,
        lt_packages_result TYPE TABLE OF zcds_mm_material_packages,
        ls_new_package     TYPE zcds_mm_material_packages.

  DATA: vl_objnum TYPE matnr,
        vl_status TYPE bapi_status,
        vl_std    TYPE bapi1003_key-stdclass,
        wl_char   TYPE bapi1003_alloc_values_char,
        tl_char   TYPE TABLE OF bapi1003_alloc_values_char,
        tl_num    TYPE TABLE OF bapi1003_alloc_values_num,
        tl_curr   TYPE TABLE OF bapi1003_alloc_values_curr,
        tl_return TYPE TABLE OF bapiret2,
        ls_return TYPE bapiret2.

  FIELD-SYMBOLS: <fs_filter> TYPE /iwbep/s_mgw_select_option,
                 <fs_pack>   TYPE zcds_mm_material_packages,
                 <lv_top>    TYPE i,
                 <lv_skip>   TYPE i.

  lt_filter = io_tech_request_context->get_filter( )->get_filter_select_options( ).
  lv_top = io_tech_request_context->get_top( ).
  lv_skip = io_tech_request_context->get_skip( ).


  LOOP AT lt_filter ASSIGNING <fs_filter>.
    CASE <fs_filter>-property.
      WHEN 'MATERIALID'.  MOVE-CORRESPONDING <fs_filter>-select_options TO rl_materialid.
      WHEN 'PLANTCODE'.   MOVE-CORRESPONDING <fs_filter>-select_options TO rl_plantcode.
      WHEN 'COMPANYCODE'. MOVE-CORRESPONDING <fs_filter>-select_options TO rl_companycode.
    ENDCASE.
  ENDLOOP.

  SELECT *
    FROM zcds_mm_material_packages
    WHERE ( materialId  IS INITIAL OR materialId  IN @rl_materialid )
     AND  ( plantCode   IS INITIAL OR plantCode   IN @rl_plantcode )
     AND  ( companyCode IS INITIAL OR companyCode IN @rl_companycode )
    ORDER BY materialid
    INTO TABLE @lt_packages
    OFFSET @lv_skip
    UP TO @lv_top ROWS.


  IF lt_packages IS INITIAL.
    RETURN.
  ENDIF.

  LOOP AT lt_packages ASSIGNING <fs_pack>.

    CLEAR: tl_char, tl_num, tl_curr, tl_return.

    ls_new_package = <fs_pack>.

    IF <fs_pack>-isBlocked is not initial.

      vl_objnum = <fs_pack>-materialId.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = vl_objnum
        IMPORTING
          output = vl_objnum.

      CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
        EXPORTING
          objectkey        = vl_objnum
          objecttable      = 'MARA'
          classnum         = 'BLOQINTEGRACAO'
          classtype        = '001'
          keydate          = '99991231'
          unvaluated_chars = 'O'
          language         = sy-langu
        IMPORTING
          status           = vl_status
          standardclass    = vl_std
        TABLES
          allocvaluesnum   = tl_num
          allocvalueschar  = tl_char
          allocvaluescurr  = tl_curr
          return           = tl_return.

      READ TABLE tl_return INTO ls_return WITH KEY type = 'E'.
      IF sy-subrc = 0.

        CONTINUE.
      ENDIF.

      IF tl_char IS NOT INITIAL.
        READ TABLE tl_char INTO wl_char WITH KEY charact = 'ACACIA'.
        IF sy-subrc = 0 AND wl_char-value_neutral = abap_true.
          READ TABLE tl_char TRANSPORTING NO FIELDS
            WITH KEY charact = 'CENTROS' value_neutral = <fs_pack>-plantCode.
          IF sy-subrc = 0.
            ls_new_package-isBlocked = abap_true.
          ELSE.
            ls_new_package-isBlocked = abap_false.
          ENDIF.
        ELSE.
          ls_new_package-isBlocked = abap_false.
        ENDIF.
      ELSE.

        IF <fs_pack>-mstde LE sy-datum AND
           <fs_pack>-mstdv LE sy-datum AND
           <fs_pack>-mstae NE '07'      AND
           <fs_pack>-mstav EQ '02'.
          ls_new_package-isBlocked = abap_false.
        ELSE.
          ls_new_package-isBlocked = abap_true.
        ENDIF.
      ENDIF.

*    ELSE.
*      ls_new_package-isBlocked = abap_false.
    ENDIF.

    APPEND ls_new_package TO lt_packages_result.

  ENDLOOP.

  copy_data_to_ref( EXPORTING is_data = lt_packages_result
                    CHANGING  cr_data = er_entityset ).

ENDMETHOD.