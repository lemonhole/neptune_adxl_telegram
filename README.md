**Автоматическая отправка графиков теста резонансов в телеграм бота**

**Описание**:

Данный гайд — копия [гайда от Tombraider2006](https://github.com/Tombraider2006/klipperFB6/blob/main/macros/telegram_adxl.md), переписанная под дрыгу (разделены калибровки X и Y) + убрана необходимость менять имя пользователя для хоста.<br>
Если есть вопросы, пишите их в [чат по нептунам](https://t.me/ELEGOO_Neptune_3_and_4_series), тэгая меня — @tootiredtoday

**Гайд**:

Помимо установленных клиппера, тг-бота и датчика ADXL вам понадобится G-Code Shell Command Extension. 

1. Для этого подключаемся к хосту по SSH (через putty или mobaxterm). Вводим в консоль:

```
~/kiauh/kiauh.sh
```
Если будет спрашивать "Do you want to update now?", вводите "n" (No)<br>
Если будет спрашивать "Would you like to try out KIAUH v6?", вводите "2" (No)<br>
Выбираем 4 пункт "Advanced", там ищем "[G-Code Shell Command]" — устанавливаем, выходим из kiauh, соединение по SSH не закрываем — дальше еще понадобится.

2. В папке с конфигами (где лежит printer.cfg) создаем папку adxl_results.<br>
Туда же (в папку с конфигами) кидаем этот файл [shaper_calibrate.sh](https://github.com/lemonhole/neptune_adxl_telegram/blob/main/shaper_calibrate.sh) <br>
Либо создаем его там сами, копируя в него следующий код:

```
#! /bin/bash
OUTPUT_FOLDER=config/adxl_results
PRINTER_DATA=$HOME/printer_data
KLIPPER_SCRIPTS_LOCATION=~/klipper/scripts
RESONANCE_CSV_LOCATION=tmp
if [ ! -d  /$PRINTER_DATA/$OUTPUT_FOLDER/ ] #Check if we have an output folder
then
    mkdir /$PRINTER_DATA/$OUTPUT_FOLDER/
fi

cd /$RESONANCE_CSV_LOCATION/

shopt -s nullglob
set -- resonances*.csv

if [ "$#" -gt 0 ]
then
    for each_file in resonances*.csv
    do
        $KLIPPER_SCRIPTS_LOCATION/calibrate_shaper.py $each_file -o /$PRINTER_DATA/$OUTPUT_FOLDER/${each_file:0:12}.png # check
        rm /$RESONANCE_CSV_LOCATION/$each_file
    done
else
    echo "Something went wrong, no csv found to process"
fi
```

3. Через консоль делаем файл исполняемым:

```
cd ~/printer_data/config/
chmod +x ./shaper_calibrate.sh
```

4. В `printer.cfg` добавим следущий блок с макросами:

```
[respond]

[gcode_macro ADXL_X_TG]
description: график шейперов в телеграм
gcode:
	{% set HZ_PER_SEC = params.HZ_PER_SEC|default(1)|float %} #Parse parameters
	{% set POSITION_X = params.POSITION_X|default(117.5)|int %}
	{% set POSITION_Y = params.POSITION_Y|default(117.5)|int %}
	{% set POSITION_Z = params.POSITION_Z|default(30)|int %}
    	{% set min_freq = params.FREQ_START|default(5)|float %}
    	{% set max_freq = params.FREQ_END|default(133.33)|float %}

	{% if printer.toolhead.homed_axes != 'xyz' %} #home if not homed
		G28
	{% endif %}
	TEST_RESONANCES AXIS=X HZ_PER_SEC={ HZ_PER_SEC } POINT={ POSITION_X },{ POSITION_Y },{POSITION_Z} FREQ_START={min_freq} FREQ_END={max_freq}
	RUN_SHELL_COMMAND CMD=shaper_calibrate
	RESPOND PREFIX=tg_send_image MSG="path=['../../printer_data/config/adxl_results/resonances_x.png'], message='Результат проверки шейперов по X' "

[gcode_macro ADXL_Y_TG]
description: график шейперов в телеграм
gcode:
	{% set HZ_PER_SEC = params.HZ_PER_SEC|default(1)|float %} #Parse parameters
	{% set POSITION_X = params.POSITION_X|default(117.5)|int %}
	{% set POSITION_Y = params.POSITION_Y|default(117.5)|int %}
	{% set POSITION_Z = params.POSITION_Z|default(30)|int %}
    	{% set min_freq = params.FREQ_START|default(5)|float %}
    	{% set max_freq = params.FREQ_END|default(133.33)|float %}

	{% if printer.toolhead.homed_axes != 'xyz' %} #home if not homed
		G28
	{% endif %}
	TEST_RESONANCES AXIS=Y HZ_PER_SEC={ HZ_PER_SEC } POINT={ POSITION_X },{ POSITION_Y },{POSITION_Z} FREQ_START={min_freq} FREQ_END={max_freq}
	RUN_SHELL_COMMAND CMD=shaper_calibrate
	RESPOND PREFIX=tg_send_image MSG="path=['../../printer_data/config/adxl_results/resonances_y.png'], message='Результат проверки шейперов по Y' "

[gcode_shell_command shaper_calibrate]
command: bash ../printer_data/config/shaper_calibrate.sh
timeout: 600.
verbose: True
```
Примечание:<br> 
a) Параметры 117.5 в следующих строках — это центр стола по X и Y соотвественно (меняйте сразу при необходимости в обоих макросах):<br>
	`{% set POSITION_X = params.POSITION_X|default(117.5)|int %}`<br>
	`{% set POSITION_Y = params.POSITION_Y|default(117.5)|int %}`<br>
 
b) Если бот установлен не в `home/ваше_имя_хоста/moonraker-telegram-bot/bot` (из kiauh по умолчанию он ставится туда — скорее всего, и у вас он там), то замените `../../` на `home/ваше_имя_хоста/` в строках `RESPOND PREFIX=tg_send_image MSG="path=['../../`
 
Работает это следующим образом:

1. Макрос вызывается с нужными параметрами, при необходимости возвращает оси в исходное положение и приступает к стандартному тестированию шейперов по обеим осям.<br>
2. Макрос вызывает выполнение сценария, который запускает программу klipper python для каждого сгенерированного файла csv. Впоследствии он удаляет файлы csv, чтобы избежать путаницы при запуске нескольких тестов один за другим. Выходные изображения помещаются в подпапку в папке журналов, чтобы вы могли легко получить к ним доступ через веб-интерфейс, если это необходимо.<br>
3. Макрос завершается отправкой файла вашему телеграмм-боту. Помимо того, что бот легко доступен, теперь он может выступать в качестве вашего архива измерений.
