**Автоматическая отправка графиков теста резонансов в телеграм бота**

**Описание**:

Данный гайд — копия гайда от Tombraider2006, переписанная под Neptune 3 Pro на клиппере с хостом в виде BTT Pi.<br>
Ссылка на оригинальный гайд: https://github.com/Tombraider2006/klipperFB6/blob/main/macros/telegram_adxl.md<br>
Если имя пользователя у вас не "biqu" (по умолчанию на BTT Pi 1.2), то заменяйте на своё (по гайду есть напоминания об этом).

Если есть вопросы, пишите их в чат по нептунам: https://t.me/ELEGOO_Neptune_3_and_4_series, тэгая меня — @tootiredtoday

**Гайд**:

Помимо установленных клиппера, тг-бота и датчика ADXL вам понадобится G-Code Shell Command Extension. 

1. Для этого подключаемся к хосту по SSH (через putty или mobaxterm). Вводим в консоль:

```
~/kiauh/kiauh.sh
```
Если будет спрашивать "Do you want to update now?", вводите "n" (No)<br>
Если будет спрашивать "Would you like to try out KIAUH v6?", вводите "2" (No)<br>
Выбираем 4 пункт "Advanced", там ищем "[G-Code Shell Command]" — устанавливаем, выходим.<br>
Соединение по SSH не закрываем — еще понадобится.

2. В папке с конфигами (где лежит printer.cfg) создаем папку adxl_results.<br>
Там же (в папке с конфигами) создаем файл `shaper_calibrate.sh`.<br>
В него копируем следующий код:

```
#! /bin/bash
OUTPUT_FOLDER=config/adxl_results
PRINTER_DATA=home/biqu/printer_data
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
Примечание:<br>
a) Файл также можно создать на ПК блокнотом, скопировав содержимое выше, и закинуть в папку с конфигами — важно только сменить расширение с .txt на .sh<br>
b) Строка "PRINTER_DATA=home/biqu/printer_data" — если имя пользователя не `biqu`, меняем на своё.

3. Через консоль делаем файл исполняемым:

```
cd ~/printer_data/config/
chmod +x ./shaper_calibrate.sh
```

4. В `printer.cfg` добавим следущий блок:

```
[respond]

[gcode_macro ADXL_X_TG]
description: график шейперов в телеграм
gcode:
	{% set HZ_PER_SEC = params.HZ_PER_SEC|default(1)|float %} #Parse parameters
	{% set POSITION_X = params.POSITION_X|default(117.5)|int %}
	{% set POSITION_Y = params.POSITION_Y|default(117.5)|int %}
	{% set POSITION_Z = params.POSITION_Z|default(30)|int %}

	{% if printer.toolhead.homed_axes != 'xyz' %} #home if not homed
		G28
	{% endif %}
	TEST_RESONANCES AXIS=X HZ_PER_SEC={ HZ_PER_SEC } POINT={ POSITION_X },{ POSITION_Y },{POSITION_Z}
	RUN_SHELL_COMMAND CMD=shaper_calibrate
	RESPOND PREFIX=tg_send_image MSG="path=['../../printer_data/config/adxl_results/resonances_x.png'], message='Результат проверки шейперов по X' "

[gcode_macro ADXL_Y_TG]
description: график шейперов в телеграм
gcode:
	{% set HZ_PER_SEC = params.HZ_PER_SEC|default(1)|float %} #Parse parameters
	{% set POSITION_X = params.POSITION_X|default(117.5)|int %}
	{% set POSITION_Y = params.POSITION_Y|default(117.5)|int %}
	{% set POSITION_Z = params.POSITION_Z|default(30)|int %}

	{% if printer.toolhead.homed_axes != 'xyz' %} #home if not homed
		G28
	{% endif %}
	TEST_RESONANCES AXIS=Y HZ_PER_SEC={ HZ_PER_SEC } POINT={ POSITION_X },{ POSITION_Y },{POSITION_Z}
	RUN_SHELL_COMMAND CMD=shaper_calibrate
	RESPOND PREFIX=tg_send_image MSG="path=['../../printer_data/config/adxl_results/resonances_y.png'], message='Результат проверки шейперов по Y' "

[gcode_shell_command shaper_calibrate]
command: bash /home/biqu/printer_data/config/shaper_calibrate.sh
timeout: 600.
verbose: True
```
Примечание:<br> 
a) Параметры 117.5 в этих строках — это центр стола по X и Y соотвественно (меняйте сразу при необходимости в обоих макросах):<br>
	`{% set POSITION_X = params.POSITION_X|default(117.5)|int %}`<br>
	`{% set POSITION_Y = params.POSITION_Y|default(117.5)|int %}`<br>

b) Если имя пользователя не `biqu` меняем на своё в строках:<br>
```
command: bash /home/biqu/printer_data/config/shaper_calibrate.sh
```
c) Бот должен быть установлен в home/имя_хоста/moonraker-telegram-bot/bot (из kiauh по умолчанию он ставится туда — скорее всего, и у вас он там).<br>
Если ваш бот стоит не там, то замените `../../` в макросах выше на `home/ваше_имя_хоста/`
 
Работает это следующим образом:

1. Макрос вызывается с нужными параметрами, при необходимости возвращает оси в исходное положение и приступает к стандартному тестированию шейперов по обеим осям.<br>
2. Макрос вызывает выполнение сценария, который запускает программу klipper python для каждого сгенерированного файла csv. Впоследствии он удаляет файлы csv, чтобы избежать путаницы при запуске нескольких тестов один за другим. Выходные изображения помещаются в подпапку в папке журналов, чтобы вы могли легко получить к ним доступ через веб-интерфейс, если это необходимо.<br>
3. Макрос завершается отправкой обоих файлов вашему телеграмм-боту. Помимо того, что бот легко доступен, теперь он может выступать в качестве вашего архива измерений.
