//
// Пример для PIC32 на языке ассемблера.
// Файл имеет расширение .S - ассебмлер с препроцессором Си.
// Copyright (C) 2012 Сергей Вакуленко
//

// Включаем набор стандартных определений для микроконтроллера PIC32.
#include <p32xxxx.h>

        .text                       // Начинаем секцию выполняемого кода.
        .set noreorder              // Отключаем переупорядочивание инструкций

//
// Функция ожидания, параметр в миллисекундах.
//
delay:  .globl  delay               // Помечаем метку delay как глобальную

        li      t0, 40000           // В зависимости от частоты процессора
        mul     t1, a0, t0          // Вычисляем нужное количество тактов
1:
        bne     t1, zero, 1b        // Крутим цикл ожидания
        addiu   t1, -1

        j       ra                  // Возврат
        nop

//
// Выполнение начинается с метки main.
//
main:   .global main                // Помечаем метку main как глобальную

        //
        // Включаем кэш, ускоряем обращение к памяти.
        //
        li      v0, 2               // Отключаем кэш, два такта ожидания
        la      t0, CHECON
        sw      v0, (t0)            // CHECON := 2

        li      v0, 0x40            // Ноль тактов ожидания для RAM
        la      t0, BMXCONCLR
        sw      v0, (t0)            // BMXCONCLR := 0x40

        li      v0, 0x30            // Включаем кэш
        la      t0, CHECONSET
        sw      v0, (t0)            // CHECONSET := 0x30

        mfc0    v0, _CP0_CONFIG
        ori     v0, 3
        mtc0    v0, _CP0_CONFIG     // Разрешаем кэширование сегмента kseg0

        //
        // Сигналы от кнопок используем как входы.
        //
        li      v0, 1 << 8
        la      t0, TRISGSET
        sw      v0, (t0)            // Сигнал 11 (RG8) как вход от первой кнопки

        li      v0, 1 << 7
        la      t0, TRISGSET
        sw      v0, (t0)            // Сигнал 12 (RG7) как вход от второй кнопки

        //
        // Сигналы управления светодиодами - выходы.
        //
        li      v0, 1 << 6
        la      t0, TRISGCLR
        sw      v0, (t0)            // Сигнал 13 (RG6) - выход для светодиода 1

        li      v0, 1 << 0
        la      t0, TRISFCLR
        sw      v0, (t0)            // Сигнал RF0 - выход для светодиода 2

        la      s0, PORTG           // Адрес PORTG храним в регистре s0
        la      s1, LATGSET         // Адрес LATGSET храним в регистре s1
        la      s2, LATGCLR         // Адрес LATGCLR храним в регистре s2
        la      s3, LATFSET         // Адрес LATGSET храним в регистре s3
        la      s4, LATFCLR         // Адрес LATGCLR храним в регистре s4

loop:                               // Начало бесконечного цикла
        li      t0, 0               // Переменная need_wait в регистре s0

        //
        // Опрашиваем первую кнопку.
        //
        lw      v0, (s0)            // Опрашиваем порт G
        ext     v0, v0, 8, 1        // Сигнал RG8
        beq     v0, zero, 1f        // Переход, если кнопка нажата
        nop

        // Не нажата - гасим первый светодиод.
        li      v0, 1 << 6
        sw      v0, (s2)            // Запись в LATGCLR, сигнал RG6
        li      t0, 1               // Установка need_wait в 1
1:
        //
        // Опрашиваем вторую кнопку.
        //
        lw      v0, (s0)            // Опрашиваем порт G
        ext     v0, v0, 7, 1        // Сигнал RG7
        beq     v0, zero, 2f        // Переход, если кнопка нажата
        nop

        // Не нажата - гасим второй светодиод.
        li      v0, 1 << 0
        sw      v0, (s4)            // Запись в LATFCLR, сигнал RF0
        li      t0, 1               // Установка need_wait в 1
2:
        // Если надо, подождём.
        beq     t0, zero, 3f        // Переход, если need_wait равно 0
        nop

        jal     delay               // Вызов delay(150)
        li      a0, 150
3:
        //
        // Зажигаем оба светодиода.
        //
        li      v0, 1 << 6
        sw      v0, (s1)            // Запись в LATGSET, сигнал RG6
        li      v0, 1 << 0
        sw      v0, (s3)            // Запись в LATFSET, сигнал RF0
        jal     delay               // Вызов delay(50)
        li      a0, 50

        j       loop                // Бесконечный цикл
        nop
