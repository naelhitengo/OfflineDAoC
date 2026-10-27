#!/usr/bin/env python3
"""Exemples pour lire et modifier la base SQLite d'Offline DAoC (opendaoc.sqlite3.db).

Aucune dependance : Python 3 standard (module sqlite3). Non execute lors de sa redaction
(aucune base n'est presente dans le depot) : les noms de tables et de colonnes viennent
du code C# (voir docs_ggr/points-de-competences.md) et se verifient avec "tables"/"schema".

Lecture (sans risque, base ouverte en lecture seule) :
    python exemples_sqlite.py DB tables
    python exemples_sqlite.py DB schema DOLCharacters
    python exemples_sqlite.py DB find-char MonPerso
    python exemples_sqlite.py DB show-specs MonPerso

Modification (apercu par defaut ; --apply pour ecrire, serveur ARRETE) :
    python exemples_sqlite.py DB set-specs MonPerso "Sword=50,Shields=50" [--apply]
    python exemples_sqlite.py DB set-priv NomDuCompte 2 [--apply]
    python exemples_sqlite.py DB set-prop spec_points_rate 2.0 [--apply]

--apply : refuse si le port 10300 repond (serveur actif), sauvegarde la base
(API backup de sqlite3) dans un fichier horodate a cote du .db, puis modifie dans UNE
transaction et verifie qu'une seule ligne est touchee (sinon annule).
"""
import argparse
import socket
import sqlite3
import sys
import time
from pathlib import Path


def connect_ro(db):
    return sqlite3.connect(Path(db).resolve().as_uri() + "?mode=ro", uri=True)


def server_running(port=10300):
    with socket.socket() as s:
        s.settimeout(0.5)
        return s.connect_ex(("127.0.0.1", port)) == 0


def backup(db):
    target = Path(db).with_name(f"{Path(db).stem}.backup-{time.strftime('%Y%m%d-%H%M%S')}.db")
    src, dst = sqlite3.connect(db), sqlite3.connect(target)
    with dst:
        src.backup(dst)
    dst.close()
    src.close()
    return target


def one_row(con, sql, params):
    rows = con.execute(sql, params).fetchall()
    if len(rows) != 1:
        sys.exit(f"Attendu 1 ligne, trouve {len(rows)} pour {params}.")
    return rows[0]


def parse_specs(text):
    """'Sword|50;Shields|42' -> [['Sword', 50], ['Shields', 42]] (ordre conserve)."""
    out = []
    for item in (text or "").split(";"):
        if "|" in item:
            key, level = item.rsplit("|", 1)
            out.append([key, int(level)])
    return out


def format_specs(specs):
    return ";".join(f"{key}|{level}" for key, level in specs)


def write(db, apply, sql, params, label):
    """Apercu, ou sauvegarde + transaction + controle du nombre de lignes."""
    print(f"{label}\n  SQL    : {sql}\n  params : {params}")
    if not apply:
        print("Apercu seulement : ajouter --apply pour ecrire (serveur arrete).")
        return
    if server_running():
        sys.exit("Le port 10300 repond : arretez le serveur avant d'ecrire.")
    print("Sauvegarde :", backup(db))
    con = sqlite3.connect(db)
    try:
        with con:  # commit si tout va bien, rollback sur exception
            cur = con.execute(sql, params)
            if cur.rowcount != 1:
                raise RuntimeError(f"{cur.rowcount} lignes touchees (1 attendue) : annule.")
        print("OK, 1 ligne modifiee.")
    finally:
        con.close()


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("db")
    p.add_argument("cmd", choices=["tables", "schema", "find-char", "show-specs",
                                   "set-specs", "set-priv", "set-prop"])
    p.add_argument("args", nargs="*")
    p.add_argument("--apply", action="store_true")
    a = p.parse_args()

    if a.cmd == "tables":
        with connect_ro(a.db) as con:
            for (name,) in con.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"):
                print(name)
    elif a.cmd == "schema":
        with connect_ro(a.db) as con:
            for cid, name, typ, notnull, default, pk in con.execute(f'PRAGMA table_info("{a.args[0]}")'):
                print(f"{cid:3} {name:35} {typ:12} notnull={notnull} pk={pk}")
    elif a.cmd == "find-char":
        with connect_ro(a.db) as con:
            for row in con.execute(
                    "SELECT DOLCharacters_ID, Name, AccountName, Class, Level FROM DOLCharacters "
                    "WHERE Name LIKE ?", (a.args[0],)):
                print(row)
    elif a.cmd == "show-specs":
        with connect_ro(a.db) as con:
            cid, name, level, specs = one_row(
                con, "SELECT DOLCharacters_ID, Name, Level, SerializedSpecs FROM DOLCharacters WHERE Name = ?",
                (a.args[0],))
        print(f"{name} (niveau {level}, id {cid})")
        for key, lvl in parse_specs(specs):
            print(f"  {key:30} {lvl}")
    elif a.cmd == "set-specs":
        name, wanted = a.args[0], dict(x.split("=", 1) for x in a.args[1].split(","))
        with connect_ro(a.db) as con:
            cid, specs = one_row(con, "SELECT DOLCharacters_ID, SerializedSpecs FROM DOLCharacters WHERE Name = ?",
                                 (name,))
        current = parse_specs(specs)
        known = {key for key, _ in current}
        for key, lvl in wanted.items():
            if key in known:
                for item in current:
                    if item[0] == key:
                        item[1] = int(lvl)
            else:
                current.append([key, int(lvl)])  # ligne valide pour la classe mais jamais entrainee
        write(a.db, a.apply, "UPDATE DOLCharacters SET SerializedSpecs = ? WHERE DOLCharacters_ID = ?",
              (format_specs(current), cid), f"{name}: {specs}\n  -> {format_specs(current)}")
    elif a.cmd == "set-priv":
        write(a.db, a.apply, "UPDATE Account SET PrivLevel = ? WHERE Name = ?",
              (int(a.args[1]), a.args[0]), f"Compte {a.args[0]} -> PrivLevel {a.args[1]} (1 joueur, 2 GM, 3 admin)")
    elif a.cmd == "set-prop":
        write(a.db, a.apply, 'UPDATE ServerProperty SET "Value" = ? WHERE "Key" = ?',
              (a.args[1], a.args[0]), f"ServerProperty {a.args[0]} = {a.args[1]}")


if __name__ == "__main__":
    main()
