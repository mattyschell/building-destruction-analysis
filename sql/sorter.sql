DECLARE
    l_ids SYS.ODCINUMBERLIST :=
        SYS.ODCINUMBERLIST(
            1005270,1017106,1064495
        );

    l_ordered SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();
    l_current NUMBER;
    l_next    NUMBER;
BEGIN
    -- Start from the first requested ID.
    l_current := l_ids(1);
    l_ordered.EXTEND;
    l_ordered(l_ordered.COUNT) := l_current;

    WHILE l_ordered.COUNT < l_ids.COUNT LOOP
        BEGIN
            SELECT doitt_id
            INTO l_next
            FROM (
                SELECT p.doitt_id,
                       SDO_GEOM.SDO_DISTANCE(p.shape, c.shape, 0.005) AS dist
                FROM bldg.building_evw p
                CROSS JOIN (
                    SELECT shape
                    FROM bldg.building_evw
                    WHERE doitt_id = l_current
                      AND shape IS NOT NULL
                ) c
                WHERE p.doitt_id IN (SELECT COLUMN_VALUE FROM TABLE(l_ids))
                  AND p.shape IS NOT NULL
                  AND p.doitt_id NOT IN (SELECT COLUMN_VALUE FROM TABLE(l_ordered))
                ORDER BY dist NULLS LAST, p.doitt_id
            )
            WHERE ROWNUM = 1;

            l_ordered.EXTEND;
            l_ordered(l_ordered.COUNT) := l_next;
            l_current := l_next;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EXIT;
        END;
    END LOOP;

    FOR i IN 1 .. l_ordered.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(l_ordered(i));
    END LOOP;
END;
