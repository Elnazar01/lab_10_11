-- Поиск по шаблону
CREATE OR REPLACE FUNCTION search_by_pattern(pattern TEXT)
RETURNS TABLE(name TEXT, phone_number TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM phonebookdb
    WHERE name ILIKE '%' || pattern || '%'
       OR phone_number ILIKE '%' || pattern || '%';
END;
$$ LANGUAGE plpgsql;

-- Добавить или обновить одного пользователя
CREATE OR REPLACE PROCEDURE insert_or_update_user(p_name TEXT, p_phone TEXT)
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM phonebookdb WHERE name = p_name) THEN
        UPDATE phonebookdb SET phone_number = p_phone WHERE name = p_name;
    ELSE
        INSERT INTO phonebookdb(name, phone_number) VALUES (p_name, p_phone);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Добавление списка пользователей с валидацией — теперь это ФУНКЦИЯ
CREATE OR REPLACE FUNCTION insert_users_with_validation(user_list TEXT[][])
RETURNS TABLE(name TEXT, phone_number TEXT) AS $$
DECLARE
    i INTEGER := 1;
    user_name TEXT;
    user_phone TEXT;
BEGIN
    WHILE i <= array_length(user_list, 1) LOOP
        user_name := user_list[i][1];
        user_phone := user_list[i][2];

        IF char_length(user_phone) = 11 AND user_phone ~ '^[0-9]+$' THEN
            CALL insert_or_update_user(user_name, user_phone);
        ELSE
            RETURN NEXT (user_name, user_phone);
        END IF;

        i := i + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Постраничный вывод
CREATE OR REPLACE FUNCTION get_users_by_page(p_limit INT, p_offset INT)
RETURNS TABLE(name TEXT, phone_number TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM phonebookdb
    ORDER BY name
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Удаление по имени или номеру
CREATE OR REPLACE PROCEDURE delete_by_name_or_phone(p_value TEXT)
AS $$
BEGIN
    DELETE FROM phonebookdb
    WHERE name = p_value OR phone_number = p_value;
END;
$$ LANGUAGE plpgsql;
