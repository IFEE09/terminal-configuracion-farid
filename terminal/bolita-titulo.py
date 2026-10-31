#!/usr/bin/env python3
"""Corre un comando en su propia terminal virtual y antepone un prefijo (la bolita
de color de la pestaña) a cada título que el comando ponga con OSC 0/1/2.

Uso: bolita-titulo.py "<prefijo>" comando [args...]
Lo llama la función `claude` de ~/.zshrc para que la bolita no se borre cuando
Claude Code cambia el título de la pestaña.
"""
import errno
import fcntl
import os
import pty
import select
import signal
import sys
import termios
import tty

prefijo = sys.argv[1].encode()
comando = sys.argv[2:]

INICIOS = (b"\x1b]0;", b"\x1b]1;", b"\x1b]2;")
PARCIALES = (b"\x1b]", b"\x1b]0", b"\x1b]1", b"\x1b]2")


def con_prefijo(datos):
    for ini in INICIOS:
        datos = datos.replace(ini, ini + prefijo)
    return datos


def escribir(fd, datos):
    while datos:
        try:
            n = os.write(fd, datos)
        except InterruptedError:
            continue
        datos = datos[n:]


def copiar_tamano(destino):
    try:
        tam = fcntl.ioctl(sys.stdin.fileno(), termios.TIOCGWINSZ, b"\0" * 8)
        fcntl.ioctl(destino, termios.TIOCSWINSZ, tam)
    except OSError:
        pass


pid, maestro = pty.fork()
if pid == 0:
    os.execvp(comando[0], comando)

copiar_tamano(maestro)


def al_cambiar_tamano(_s, _f):
    copiar_tamano(maestro)
    try:
        os.kill(pid, signal.SIGWINCH)
    except OSError:
        pass


signal.signal(signal.SIGWINCH, al_cambiar_tamano)

entrada = sys.stdin.fileno()
salida = sys.stdout.fileno()
modo_original = termios.tcgetattr(entrada)
tty.setraw(entrada)

pendiente = b""
try:
    while True:
        try:
            listos, _, _ = select.select([entrada, maestro], [], [])
        except InterruptedError:
            continue
        if maestro in listos:
            try:
                datos = os.read(maestro, 65536)
            except OSError as e:
                if e.errno == errno.EIO:
                    break
                raise
            if not datos:
                break
            datos = pendiente + datos
            pendiente = b""
            # Un inicio de título cortado entre dos lecturas se guarda para la siguiente.
            for p in sorted(PARCIALES, key=len, reverse=True):
                if datos.endswith(p):
                    pendiente = p
                    datos = datos[: -len(p)]
                    break
            escribir(salida, con_prefijo(datos))
        if entrada in listos:
            datos = os.read(entrada, 65536)
            if not datos:
                break
            escribir(maestro, datos)
finally:
    if pendiente:
        escribir(salida, pendiente)
    termios.tcsetattr(entrada, termios.TCSAFLUSH, modo_original)

_, estado = os.waitpid(pid, 0)
sys.exit(os.waitstatus_to_exitcode(estado))
