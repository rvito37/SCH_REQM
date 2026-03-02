# SCH_REQM - Статус миграции (02.03.2026)

## Что сделано

### Компиляция и базовый запуск
- Проект компилируется и линкуется без ошибок (Harbour 3.2 + MinGW)
- GUI экран критериев (prnFace) работает: чекбоксы, выбор критериев, PgDn для запуска
- DoSched (основной движок планирования) отрабатывает без runtime ошибок

### Исправленные ошибки
| # | Ошибка | Причина | Исправление |
|---|--------|---------|-------------|
| 1 | Variable SCHED_SOURCE | DBF обрезает имена полей до 10 символов | `#xtranslate` в avxdefs.ch |
| 2 | ADS Error 5020 | Индекс на локальном диске, таблица на ADS | SafeDbSetIndex() обёртка |
| 3 | ADS Error 6420 | COPY TO с ADSCDX на локальный путь | Override COPY TO -> DBFCDX |
| 4 | Undefined GETSEQBSTAT | Функция в макро-скомпилированном индексе | Stub функции |
| 5 | Argument error GetHie_2 | Был stub "1", нужен реальный lookup | Реальная реализация из c_hierar |
| 6 | Undefined DESCEND | CT3 функция в макро-индексе | REQUEST DESCEND |
| 7 | Argument error GetRec | Возвращал NIL в .AND. цепочке | Return .T. |
| 8 | Criteria не фильтруют | GetBuffer("") -> `code $ ""` = .F. | GetBuffer_BuildAll() |
| 9 | Фильтр не применяется к d_ord | Пропущен CreateCondDb | Реализован CreateCondDb |
| 10 | Alias конфликт d_ord | d_ord не закрыт после CreateCondDb | Close d_ord (в тесте) |
| 11 | SchedIndex (test.exe) | MYRUN закомментирован, индексы не создавались | SchedIndex() через препроцессор hook |

### Текущая работа - Фильтрация критериев
**Проблема**: Даже если выбрать только "F" (Film), программа бежит на всех продуктах.

**Причина**: В оригинале `CreateCondDb` (THEREPO.PRG) создаёт отфильтрованную копию `t_ordPre` через `COPY TO ... FOR ShaiCond()`. Наш `Exec()` пропускал этот шаг.

**Исправление** (в тесте):
1. `CreateCondDb()` — копирует из d_ord только записи прошедшие ShaiCond + cbExtraCond
2. Закрывает d_ord после копирования (как в оригинале THEREPO.PRG строка 973)
3. `PrepareGenDb` открывает t_ordPre как alias "d_ord" — видит только отфильтрованные записи

**Результат**: CreateCondDb скопировал 183 записи из 13173 (только Film). Ожидаем подтверждение что PrepareGenDb теперь подхватывает t_ordPre.

### SchedIndex — интеграция индексов d_stock
**Проблема**: `MYRUN("G:\SOURCE\test.exe")` (строка 578) был закомментирован. Без него не создавались индексы `d_stocktmp.cdx` для stock lookup'ов.

**Решение**: `SchedIndex()` интегрирован в `stubs.prg`:
1. Обновляет `d_stock->seq_no` из таблицы приоритетов `c_hierar` (через `GetHie_2`)
2. Создаёт 6 условных тегов в `d_stocktmp.cdx`:
   - `viva_CZ/IL` — с value, для CZ/IL (wh3+wh4 > 0)
   - `U_viva_CZ/IL` — без value, для CZ/IL (wh3+wh4 > 0)
   - `viva_06/U_viva_06` — для wh6 (LOC $ 'IL_CZ')
3. `GetHie_2()` — реальная реализация (lookup в c_hierar), заменил stub

**Hook**: Препроцессор в `avxdefs.ch` перехватывает `@ 9,11 SAY "Preparing tempery files : Stock files index"` и вызывает `SchedIndex()` после неё.

## Архитектура
```
main.prg          -> точка входа + логирование
sch_reqm.prg      -> оригинальный код Clipper (НЕ МЕНЯТЬ!)
stubs.prg         -> совместимость (~6850 строк, 213 функций)
avxdefs.ch        -> препроцессор (truncation, overrides)
logger.prg        -> система логирования
```

## Как тестировать
1. `git pull` на рабочей машине
2. Запустить `main.exe`
3. Отметить `[X] Product type`, выбрать "F" (Film)
4. Нажать PgDn для запуска
5. На экране должен быть только тип "F", не "C" (Capacitor)
6. Отправить лог (`sch_reqm.log`) для анализа

## Что осталось
- [ ] Подтвердить работу фильтрации критериев (alias fix)
- [ ] Подтвердить работу SchedIndex (d_stocktmp.cdx создаётся)
- [ ] Сравнить выходные данные Harbour и Clipper
- [ ] Проверить что READ не выходит преждевременно
- [ ] R&R report output (закомментирован в оригинале)
