#!/bin/bash

#Based on: https://www.voztovoice.org/?q=node/97

yum -y install festival festival-devel unzip

cd /usr/share/festival/lib/voices/
wget http://www.voztovoice.org/tmp/festival-spanish.zip
unzip festival-spanish.zip

echo -e "
;(language__spanish)
(set! voice_default 'voice_el_diphone)

   (define (tts_textasterisk string mode)
    \"(tts_textasterisk STRING MODE)
    Apply tts to STRING. This function is specifically designed for
    use in server mode so a single function call may synthesize the string.
    This function name may be added to the server safe functions.\"
    (let ((wholeutt (utt.synth (eval (list 'Utterance 'Text string)))))
    (utt.wave.resample wholeutt 8000)
    (utt.wave.rescale wholeutt 5)
    (utt.send.wave.client wholeutt)))
" >> /usr/share/festival/lib/festival.scm


echo -e "
host=localhost
port=1314
festivalcommand=(tts_textasterisk "%s" 'file)(quit)\n
" >> /etc/asterisk/festival.conf

asterisk -x "reload"

echo "/usr/bin/festival_server" >> /etc/rc.local

echo "Festival se encuentra configurado. Se recomienda aplicar un reinicio de este servidor para aplicar todos los cambios - puede que funcione sin necesidad de esto..."


########## troubleshooting: ##########
#	Intenta arrancar el server con esta opción 
#		/usr/bin/festival_server -show 
#	y mira si te sale algun error. Si sale:
#		./festival_server: line 73: 3: Bad file descriptor
#	Edita el archivo festival_server y comenta la linea 73 con un #

########## run in background: ##########
#	nohup /usr/bin/festival_server &


########## Use example: ##########
#	add line in sip.conf / [general] / storesipcause=yes
#
#	add dialplan in extensions.conf
#		[macro-llamar-sipcause-festival]
#		;-------------------------------------------------------------------------------------------------------------
#		; ${ARG1}: mensaje
#		; ${ARG2}: tecnologia/peer/destino
#		; ${ARG3}: callerid(num) / n
#		; ${ARG4}: callerid(name) / n
#		; ej. - exten => _1983X.,1,Macro(llamasimple,<PEER>-CELU_LOCAL,<tecnologia/peer/destino>,<ANI-NUM>,<ANI-NAME>)
#		;-------------------------------------------------------------------------------------------------------------
#		
#		exten => s,1,NoOp(###### <${ARG1}> ######)
#		same => n,GotoIf($["${ARG3}" == "n"]?controlname:clidnumllamasimple)
#		same => n(clidnumllamasimple),Set(CALLERID(num)=${ARG3})
#		same => n(controlname),GotoIf($["${ARG4}" == "n"]?dialllamasimple:clidnamellamasimple)
#		same => n(clidnamellamasimple),Set(CALLERID(name)=${ARG4})
#		same => n(dialllamasimple),Dial(${ARG2},50,xX)
#		same => n,Set(SIPcause=${MASTER_CHANNEL(HASH(SIP_CAUSE,${CDR(dstchannel)}))});
#		same => n,Set(CDR(userfield)=${MASTER_CHANNEL(HASH(SIP_CAUSE,${CDR(dstchannel)}))})
#		same => n,Set(SIPcode=${CUT(SIPcause," ",2)})
#		same => n,NoOp(SIPcode: ${SIPcode} Destino: ${ARG2}  DIALSTATUS: ${DIALSTATUS} HANGUPCAUSE: ${HANGUPCAUSE} )
#		same => n,GotoIf($[ $["${SIPcode:0:1}" == "4"] | $["${SIPcode:0:1}" == "5"] | $["${SIPcode:0:1}" == "6"] ]?nodisponible:hangup)
#		same => n(hangup),HangUp()
#		same => n(nodisponible),Festival(el interno no se encuentra disponible. Vuelva a intentar mas tarde)
#		same => n,HangUp()
#		
#		
#		exten => _3123456,1,Answer()
#		same => n,Festival(Contactando al interno ${EXTEN:2})
#		same => n,Macro(llamar-sipcause-festival,TEST_festival,Sip/reina_trunk/${EXTEN:2},n,n)
#		same => n,HungUp()


