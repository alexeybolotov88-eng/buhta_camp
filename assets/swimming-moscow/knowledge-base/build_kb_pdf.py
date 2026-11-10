#!/usr/bin/env python3
"""Генерация офлайн PDF: База знаний администратора Swimming Moscow."""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "Swimming_Moscow_Baza_Znaniy_Admina.pdf"

pdfmetrics.registerFont(TTFont("DejaVu", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"))
pdfmetrics.registerFont(TTFont("DejaVuBold", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"))

BLUE = colors.HexColor("#084a8f")
BLUE_LIGHT = colors.HexColor("#e3f0fa")
RED = colors.HexColor("#d62828")
GREEN = colors.HexColor("#0f7a4c")
INK = colors.HexColor("#0b1f33")
MUTED = colors.HexColor("#4a657a")
LINE = colors.HexColor("#c5d6e6")
WARN_BG = colors.HexColor("#fff5f5")
OK_BG = colors.HexColor("#f1faf5")


def styles():
    base = getSampleStyleSheet()
    s = {
        "cover_badge": ParagraphStyle(
            "cover_badge", fontName="DejaVuBold", fontSize=9, textColor=colors.white,
            alignment=TA_CENTER, spaceAfter=6,
        ),
        "h1": ParagraphStyle(
            "h1", fontName="DejaVuBold", fontSize=20, textColor=BLUE,
            spaceAfter=6, leading=24,
        ),
        "subtitle": ParagraphStyle(
            "subtitle", fontName="DejaVu", fontSize=11, textColor=BLUE,
            spaceAfter=10, leading=15,
        ),
        "meta": ParagraphStyle(
            "meta", fontName="DejaVu", fontSize=9, textColor=MUTED, leading=13, spaceAfter=4,
        ),
        "h2": ParagraphStyle(
            "h2", fontName="DejaVuBold", fontSize=13, textColor=BLUE,
            spaceBefore=14, spaceAfter=8, leading=16,
        ),
        "h3": ParagraphStyle(
            "h3", fontName="DejaVuBold", fontSize=11, textColor=INK,
            spaceBefore=10, spaceAfter=5, leading=14,
        ),
        "body": ParagraphStyle(
            "body", fontName="DejaVu", fontSize=9.5, textColor=INK,
            leading=13, alignment=TA_JUSTIFY, spaceAfter=6,
        ),
        "bullet": ParagraphStyle(
            "bullet", fontName="DejaVu", fontSize=9.5, textColor=INK,
            leading=13, leftIndent=2, spaceAfter=2,
        ),
        "small": ParagraphStyle(
            "small", fontName="DejaVu", fontSize=8.5, textColor=MUTED, leading=11,
        ),
        "script": ParagraphStyle(
            "script", fontName="DejaVu", fontSize=9, textColor=INK,
            leading=12.5, leftIndent=6, spaceAfter=4,
        ),
        "quote": ParagraphStyle(
            "quote", fontName="DejaVu", fontSize=9, textColor=INK,
            leading=12.5, leftIndent=10,
            backColor=BLUE_LIGHT, borderPadding=6, spaceAfter=6,
        ),
        "th": ParagraphStyle(
            "th", fontName="DejaVuBold", fontSize=8.5, textColor=BLUE, leading=11,
        ),
        "td": ParagraphStyle(
            "td", fontName="DejaVu", fontSize=8.5, textColor=INK, leading=11,
        ),
        "warn": ParagraphStyle(
            "warn", fontName="DejaVu", fontSize=9, textColor=INK, leading=12, spaceAfter=2,
        ),
        "footer": ParagraphStyle(
            "footer", fontName="DejaVu", fontSize=8, textColor=MUTED, alignment=TA_CENTER,
        ),
    }
    return s


def p(text, style):
    return Paragraph(text.replace("\n", "<br/>"), style)


def bullets(items, style):
    flow = []
    for item in items:
        flow.append(ListItem(Paragraph(item, style), leftIndent=12, bulletColor=BLUE))
    return ListFlowable(flow, bulletType="bullet", start="•", leftIndent=10, spaceBefore=2, spaceAfter=6)


def make_table(headers, rows, col_widths):
    data = [[Paragraph(h, ParagraphStyle("th2", fontName="DejaVuBold", fontSize=8.5, textColor=BLUE, leading=11)) for h in headers]]
    for row in rows:
        data.append([Paragraph(str(c), ParagraphStyle("td2", fontName="DejaVu", fontSize=8.5, textColor=INK, leading=11)) for c in row])
    t = Table(data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), BLUE_LIGHT),
        ("GRID", (0, 0), (-1, -1), 0.4, LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f7fbfe")]),
    ]))
    return t


def callout(text, kind="warn", s=None):
    bg = WARN_BG if kind == "warn" else OK_BG
    border = RED if kind == "warn" else GREEN
    inner = Table([[p(text, s["warn"])]], colWidths=[170 * mm])
    inner.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), bg),
        ("BOX", (0, 0), (-1, -1), 0, bg),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LINEBEFORE", (0, 0), (0, -1), 3, border),
    ]))
    return inner


def add_footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("DejaVu", 8)
    canvas.setFillColor(MUTED)
    canvas.drawCentredString(
        A4[0] / 2,
        10 * mm,
        f"Swimming Moscow · База знаний администратора · стр. {doc.page}",
    )
    canvas.setStrokeColor(LINE)
    canvas.line(16 * mm, 14 * mm, A4[0] - 16 * mm, 14 * mm)
    canvas.restoreState()


def build():
    s = styles()
    story = []

    # ----- COVER -----
    badge = Table([[p("БАЗА ЗНАНИЙ · ОФЛАЙН", ParagraphStyle(
        "bb", fontName="DejaVuBold", fontSize=8, textColor=colors.white, alignment=TA_CENTER
    ))]], colWidths=[55 * mm])
    badge.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), BLUE),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
    ]))
    cover = Table([
        [badge],
        [p("Swimming Moscow", s["h1"])],
        [p("База знаний администратора", s["subtitle"])],
        [p(
            "Рабочий документ для смены: регламент, CRM, скрипты, прайс, филиалы, "
            "пробные занятия, продажи и отчётность.<br/>"
            "Без сайта и без сервера — открывайте PDF на телефоне или компьютере.",
            s["body"],
        )],
        [p(
            "Сайт: https://swimmingmoscow.ru/<br/>"
            "Каналы: Telegram / WhatsApp / телефон · заявки с сайта → Tilda-бот<br/>"
            "Версия: сентябрь 2026 · прайс обновлён",
            s["meta"],
        )],
    ], colWidths=[178 * mm])
    cover.setStyle(TableStyle([
        ("BOX", (0, 0), (-1, -1), 1.5, BLUE),
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#f3f8fc")),
        ("LEFTPADDING", (0, 0), (-1, -1), 14),
        ("RIGHTPADDING", (0, 0), (-1, -1), 14),
        ("TOPPADDING", (0, 0), (-1, -1), 10),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    story.append(cover)
    story.append(Spacer(1, 8 * mm))

    story.append(p("Содержание", s["h2"]))
    toc = [
        "1. Регламент дня и SLA",
        "2. Чек-лист смены (по часам)",
        "3. CRM, таблицы, оформление клиента",
        "4. Пробное занятие и что взять с собой",
        "5. Актуальный прайс",
        "6. Скрипты общения",
        "7. Филиалы и справки",
        "8. Продажи абонементов и персональные",
        "9. Вечерний отчёт",
        "10. Быстрые ответы (FAQ для админа)",
    ]
    story.append(bullets(toc, s["bullet"]))
    story.append(callout(
        "<b>Главное правило:</b> каждый блок общения заканчивается вашим вопросом. "
        "Запись ведём строго по таблице заполняемости. Максимум в группе — <b>10 человек</b>.",
        "ok", s,
    ))

    # ----- 1 -----
    story.append(p("1. Регламент дня и SLA", s["h2"]))
    story.append(make_table(
        ["Время", "Действие"],
        [
            ["10:00", "Отчёт о готовности к работе (утро / дата)"],
            ["с 10:00", "CRM и Amo: воронка, продление абонементов, задачи"],
            ["до 12:00", "Проверка расписания, связь с пробниками вчерашнего дня"],
            ["с 11:00", "Подтверждение визитов, оформление пробников, напоминания"],
            ["12:00–15:00", "Недошедшие, лист ожидания"],
            ["с 15:00", "Таблицы «текучка»"],
            ["до 18:00", "Напоминания новичкам на завтра"],
            ["весь день", "Входящие: сайт (Tilda-бот) → в первую очередь; TG / WA / звонки"],
            ["22:00–23:00", "Вечерний отчёт: заявки / записи / пробные / сделки / выручка"],
        ],
        [32 * mm, 146 * mm],
    ))
    story.append(make_table(
        ["Тип клиента", "Время ответа"],
        [
            ["Новый", "до 10 минут"],
            ["Повторный", "до 20 минут"],
        ],
        [50 * mm, 128 * mm],
    ))
    story.append(callout(
        "<b>Фиксация:</b> новые лиды, записи и продажи — в чат администратора подробно "
        "(источник / филиал / график). Задачи в CRM обновлять: с кем связаться, у кого кончился абонемент.",
        "warn", s,
    ))

    # ----- 2 -----
    story.append(p("2. Чек-лист смены", s["h2"]))
    story.append(p("Утро", s["h3"]))
    story.append(bullets([
        "Отправить отчёт готовности",
        "Открыть CRM → задачи (авто: конец абонементов; ручные: болезни / переносы — ставить дату следующего контакта)",
        "Проверить расписание филиалов на сегодня и завтра",
        "Разобрать заявки из Tilda-бота",
    ], s["bullet"]))
    story.append(p("День", s["h3"]))
    story.append(bullets([
        "Подтверждать визиты и пробные",
        "Оформлять новичков по чек-листу",
        "Работать с недошедшими и листом ожидания",
        "Вести таблицы заполняемости и оплат",
    ], s["bullet"]))
    story.append(p("Вечер", s["h3"]))
    story.append(bullets([
        "Напоминания новичкам на завтра (до 18:00)",
        "Сверить оплаты и записи в CRM",
        "Собрать вечерний отчёт с указанием источника каждого показателя",
    ], s["bullet"]))

    # ----- 3 -----
    story.append(p("3. CRM, таблицы, оформление клиента", s["h2"]))
    story.append(p(
        "Основные каналы: Telegram, WhatsApp, телефон. Заявки с сайта падают в Telegram-бот (Tilda) — "
        "связываемся с ними в первую очередь.",
        s["body"],
    ))
    story.append(p("Две главные таблицы", s["h3"]))
    story.append(make_table(
        ["Таблица", "Что фиксируем"],
        [
            ["Заполняемость", "График учеников и расписание филиалов. Лимит группы — 10 человек"],
            ["Оплаты", "ФИО, филиал, график, сумма, дата оплаты"],
        ],
        [40 * mm, 138 * mm],
    ))
    story.append(p("Регистрация нового клиента в CRM", s["h3"]))
    story.append(bullets([
        "Имя и фамилия",
        "Дата рождения (обязательно — для возрастной группы)",
        "Пол (М/Ж)",
        "Телефон",
        "Источник (Яндекс / 2ГИС / рекомендация / промоутер / сайт и т.д.)",
        "Сохранить и поставить галочку «Создать сделку»",
    ], s["bullet"]))
    story.append(p("Оформление новичка — последовательность", s["h3"]))
    story.append(bullets([
        "Договор",
        "Правила абонемента (быстрые ответы)",
        "Ссылка на оплату (многоразовые ссылки закреплены в шапке WhatsApp и Telegram)",
        "Внести в таблицу заполняемости по выбранному расписанию",
        "Внести в таблицу оплат (ФИ, график, сумма, дата)",
        "Добавить контакт родителя в чат с видеоотчётами",
        "В CRM сразу расписать занятия на весь период абонемента по графику",
    ], s["bullet"]))

    # ----- 4 -----
    story.append(PageBreak())
    story.append(p("4. Пробное занятие и что взять с собой", s["h2"]))
    story.append(p(
        "Пробное — полноценное занятие. Клиент может: познакомиться с тренером; понять, как проходит занятие; "
        "задать вопросы; выбрать формат (группа или индивидуально). Тренер оценивает навыки и даёт рекомендации.",
        s["body"],
    ))
    story.append(p("С собой на занятие", s["h3"]))
    story.append(bullets([
        "Очки, шапочка, купальник/плавки, шлёпанцы, полотенце",
        "Результат анализа на энтеробиоз",
        "Сменная обувь для родителя",
    ], s["bullet"]))
    story.append(callout(
        "<b>Справки:</b> особенно строго в Качаловском и Максимуме — без энтеробиоза на воду могут не пустить "
        "(в т.ч. на пробное). Всегда напоминайте до визита.",
        "warn", s,
    ))

    # ----- 5 -----
    story.append(p("5. Актуальный прайс (детская группа)", s["h2"]))
    story.append(callout(
        "Старый прайс из прежней базы знаний <b>не использовать</b>. Ниже — актуальные цены.",
        "warn", s,
    ))
    story.append(make_table(
        ["Позиция", "Условие", "Цена"],
        [
            ["Пробная тренировка", "Знакомство и адаптация", "1 000 ₽"],
            ["Абонемент 4 занятия", "1 раз в неделю", "6 400 ₽"],
            ["Абонемент 8 занятий", "2 раза в неделю", "11 100 ₽"],
            ["Абонемент 12 занятий", "3 раза в неделю", "15 200 ₽"],
            ["Разовое занятие", "Без закрепления места", "1 900 ₽"],
            ["Пакет 12 занятий", "1 раз в неделю", "17 850 ₽"],
            ["Пакет 24 занятия", "2 раза в неделю", "30 400 ₽"],
            ["Пакет 36 занятий", "3 раза в неделю", "41 600 ₽"],
            ["Персональная тренировка", "1 человек", "5 000 ₽"],
            ["Сплит-тренировка", "для двоих", "7 000 ₽"],
        ],
        [58 * mm, 70 * mm, 50 * mm],
    ))
    story.append(p(
        "Оплаты персональных занятий (кроме персональных Алексея) контролируются через тренеров. "
        "Персоналки Алексея — оплата на карту Сбербанка Алексею.",
        s["body"],
    ))

    # ----- 6 -----
    story.append(p("6. Скрипты общения", s["h2"]))
    story.append(p("6.1. Исходящий звонок по заявке", s["h3"]))
    story.append(p(
        "<b>Шаг 1.</b> «Добрый день! Меня зовут [Имя], я администратор школы плавания Swimming Moscow. "
        "Вы оставили заявку на нашем сайте. Подскажите, пожалуйста, кто планирует заниматься: взрослый или ребёнок?»",
        s["script"],
    ))
    story.append(p(
        "<b>Шаг 2.</b> Имя → возраст и филиал → уровень (занимались ли ранее).",
        s["script"],
    ))
    story.append(p(
        "<b>Шаг 3.</b> «Свободные места в группах: [актуальное из таблицы заполняемости]. "
        "Ближайшая тренировка — [дата/время]. Запишем вас на пробное занятие?»",
        s["script"],
    ))

    story.append(p("6.2. Входящий звонок", s["h3"]))
    story.append(bullets([
        "«Школа плавания Swimming Moscow, администратор [имя], добрый день!»",
        "«Подскажите, как я могу к вам обращаться?» → «Очень приятно, [Имя]!»",
        "«Кто будет заниматься, возраст и в каком филиале удобнее?»",
        "«Ранее уже занимались плаванием?»",
        "«В филиале [название] есть места. Ближайшее занятие [дата/время]. Записываемся на пробное?»",
    ], s["bullet"]))

    story.append(p("6.3. Завершение записи", s["h3"]))
    story.append(bullets([
        "Собрать ФИО ребёнка/взрослого и полную дату рождения",
        "Уточнить канал: WhatsApp или Telegram",
        "«Записала вас на [дата] в [время]. Сейчас направлю адрес, имя тренера, список вещей и напомню о визите. Остались вопросы?»",
        "«Хорошего дня, до свидания!»",
    ], s["bullet"]))
    story.append(p("Уровни для ориентира", s["h3"]))
    story.append(make_table(
        ["Уровень", "Ориентир"],
        [
            ["Начинающие 4–7 лет", "Малая чаша (где есть)"],
            ["Начинающие 7+", "Большой бассейн"],
            ["Продвинутые", "Только с разрядами / серьёзным опытом"],
        ],
        [50 * mm, 128 * mm],
    ))

    # ----- 7 -----
    story.append(p("7. Филиалы и справки", s["h2"]))
    story.append(make_table(
        ["Филиал", "Адрес / ориентир", "Возраст", "Важно"],
        [
            ["Заряд", "ул. Краснодонская, 1к1 · м. Текстильщики", "от 4 лет", "Уточнять пропуск/парковку у смены"],
            ["Восход", "Ореховый пр-д, 26", "от 3 лет", "Смотреть актуальные группы в таблице"],
            ["Максимум", "Волгоградский пр-т, 46/15с4", "от 4 лет", "Справка на энтеробиоз обязательна"],
            ["Качаловский", "ул. Каховка, 25", "от 3–4 лет", "Справка строго обязательна детям и взрослым"],
            ["Пегас", "ул. Верхние Поля, 27с1", "от 4 лет", "Новый набор — активно предлагать пробные"],
        ],
        [32 * mm, 58 * mm, 28 * mm, 60 * mm],
    ))
    story.append(callout(
        "Если в группе уже 10 человек — предлагаем другое время или лист ожидания. "
        "Не записываем «поверх» лимита.",
        "ok", s,
    ))

    # ----- 8 -----
    story.append(PageBreak())
    story.append(p("8. Продажи абонементов и персональные", s["h2"]))
    story.append(p("Абонемент / пакет", s["h3"]))
    story.append(bullets([
        "При продаже выбирать «безналичный расчёт»",
        "Срок действия — день последней тренировки ученика по расписанию",
        "Внести ученика в CRM на ближайшие дни по его графику",
        "Внести оплату в таблицу оплат",
        "Ссылки на оплату — многоразовые, закреплены сверху в WhatsApp и Telegram",
    ], s["bullet"]))
    story.append(p("Персональные", s["h3"]))
    story.append(bullets([
        "Контроль оплат через тренеров",
        "Если оплата не поступила, а занятие идёт — продажа в долг (кроме персональных Алексея)",
        "Персоналки Алексея — только на карту Сбербанка Алексею",
        "Персональная — 5 000 ₽; сплит (двое) — 7 000 ₽",
    ], s["bullet"]))

    # ----- 9 -----
    story.append(p("9. Вечерний отчёт (22:00–23:00)", s["h2"]))
    story.append(p("У каждого показателя обязательно указывать источник.", s["body"]))
    story.append(make_table(
        ["Показатель", "Что считаем"],
        [
            ["Заявки", "Новые обращения (карты Яндекс/2ГИС, рекомендация, промоутер, сайт…)"],
            ["Записи", "Новые записи на пробное или персональное"],
            ["Пробные", "Клиенты, которые реально пришли на пробную"],
            ["Сделки", "Первая продажа клиента: абонемент / пакет / разовое / персональное. Пробные — не сделка"],
            ["Выручка", "Все продажи за день — план / факт (абонементы, персоналки, разовые, пробные)"],
        ],
        [35 * mm, 143 * mm],
    ))
    story.append(p(
        "План на месяц и на день задаёт управляющий в начале месяца.",
        s["body"],
    ))

    # ----- 10 -----
    story.append(p("10. Быстрые ответы (шпаргалка админа)", s["h2"]))
    story.append(make_table(
        ["Вопрос клиента", "Короткий ответ"],
        [
            ["Сколько пробное?", "1 000 ₽, полноценная тренировка с оценкой и рекомендациями"],
            ["Что взять?", "Очки, шапочка, купальник/плавки, шлёпанцы, полотенце, энтеробиоз, сменная обувь родителю"],
            ["Сколько в группе?", "Максимум 10 человек"],
            ["Как часто ходить?", "Оптимально 2–3 раза в неделю; есть абонементы 1/2/3 р/нед и пакеты"],
            ["Можно персонально?", "Да: 5 000 ₽; сплит для двоих — 7 000 ₽"],
            ["Как оплатить?", "Безнал по ссылке из шапки чата; персоналки Алексея — на его карту Сбера"],
            ["Нет мест?", "Другое время или лист ожидания; предложить Пегас при наборе"],
            ["Перенос?", "Сообщить заранее администратору; правила зависят от типа абонемента"],
        ],
        [48 * mm, 130 * mm],
    ))

    story.append(Spacer(1, 8 * mm))
    story.append(callout(
        "<b>Как пользоваться этим файлом:</b> сохраните PDF на телефон / диск / Google Drive / WhatsApp «Избранное». "
        "Отдельный сайт и сервер не нужны. При смене прайса или филиалов — обновите этот файл и рассылку смене.",
        "ok", s,
    ))
    story.append(Spacer(1, 4 * mm))
    story.append(p(
        "Источник: внутренняя база знаний администратора Swimming Moscow + актуальный прайс и регламент смены (2026).",
        s["small"],
    ))

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=16 * mm,
        rightMargin=16 * mm,
        topMargin=14 * mm,
        bottomMargin=18 * mm,
        title="База знаний администратора — Swimming Moscow",
        author="Swimming Moscow",
    )
    doc.build(story, onFirstPage=add_footer, onLaterPages=add_footer)
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    build()
