#!/usr/bin/env python3
"""
CareConnect CLI - Demonstrație securitate baze de date Oracle.
Criptare AES-256, VPD, RBAC, Auditare, PL/SQL
"""

import oracledb
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, IntPrompt, Confirm
from rich import box
import sys
import time

console = Console()


class CareConnectCLI:
    def __init__(self):
        self.conn = None
        self.user = None
        self.role = None
        self.grad = 0
        self.last_query_time = 0  # ms
        self.last_latency = 0     # ms

    # ===========================================
    # CONEXIUNE
    # ===========================================

    def connect(self, user: str, pwd: str) -> bool:
        try:
            self.conn = oracledb.connect(
                user=user, password=pwd,
                dsn="//localhost:1521/XEPDB1"
                # Alternative formats if the above doesn't work:
                # dsn="localhost:1521/XEPDB1"
                # dsn="(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=XEPDB1)))"
            )
            self.user = user
            with self.conn.cursor() as c:
                c.execute("SELECT careconnect.get_grad_acces(), careconnect.get_role_name() FROM dual")
                self.grad, self.role = c.fetchone()
                self.grad = self.grad or 0
            return True
        except oracledb.Error as e:
            console.print(f"[red]Eroare: {e}[/red]")
            return False

    def disconnect(self):
        if self.conn:
            self.conn.close()
            self.conn = None

    # ===========================================
    # HELPERS
    # ===========================================

    def ping_db(self):
        """Măsoară latența către DB."""
        try:
            start = time.perf_counter()
            with self.conn.cursor() as c:
                c.execute("SELECT 1 FROM dual")
                c.fetchone()
            self.last_latency = (time.perf_counter() - start) * 1000
        except:
            self.last_latency = -1

    def header(self):
        console.clear()
        self.ping_db()
        
        # Colorează latența în funcție de valoare
        if self.last_latency < 0:
            latency_str = "[red]OFFLINE[/red]"
        elif self.last_latency < 50:
            latency_str = f"[green]{self.last_latency:.0f}ms[/green]"
        elif self.last_latency < 150:
            latency_str = f"[yellow]{self.last_latency:.0f}ms[/yellow]"
        else:
            latency_str = f"[red]{self.last_latency:.0f}ms[/red]"
        
        # Colorează timpul ultimului query
        if self.last_query_time > 0:
            if self.last_query_time < 100:
                query_str = f"[green]{self.last_query_time:.0f}ms[/green]"
            elif self.last_query_time < 500:
                query_str = f"[yellow]{self.last_query_time:.0f}ms[/yellow]"
            else:
                query_str = f"[red]{self.last_query_time:.0f}ms[/red]"
            timing = f"Ping: {latency_str} | Query: {query_str}"
        else:
            timing = f"Ping: {latency_str}"
        
        console.print(Panel(
            f"[bold cyan]CareConnect[/bold cyan] | {self.user} ([yellow]{self.role}[/yellow]) | Grad: {self.grad}\n"
            f"[dim]{timing}[/dim]",
            box=box.DOUBLE
        ))

    def query(self, sql, params=None):
        start = time.perf_counter()
        with self.conn.cursor() as c:
            c.execute(sql, params or {})
            result = c.fetchall()
        self.last_query_time = (time.perf_counter() - start) * 1000
        return result

    def execute(self, sql, params=None):
        start = time.perf_counter()
        with self.conn.cursor() as c:
            c.execute(sql, params or {})
        self.last_query_time = (time.perf_counter() - start) * 1000

    def show_table(self, rows, columns, show_time=True):
        if not rows:
            console.print("[yellow]Nu există date.[/yellow]")
            return
        t = Table(box=box.ROUNDED)
        for col in columns:
            t.add_column(col)
        for row in rows:
            t.add_row(*[str(v) if v else "-" for v in row])
        console.print(t)
        if show_time and self.last_query_time > 0:
            console.print(f"[dim]({len(rows)} rânduri în {self.last_query_time:.0f}ms)[/dim]")

    def wait(self):
        Prompt.ask("\n[dim]Enter pentru a continua[/dim]")

    def error(self, e):
        """Afișează erori Oracle în format friendly."""
        msg = str(e)
        errors = {
            "ORA-20010": "Nu ai permisiunea să decriptezi CNP!",
            "ORA-20011": "Pacient negăsit!",
            "ORA-20020": "Doar medicii pot adăuga fișe!",
            "ORA-20030": "Doar medicii pot modifica fișe!",
            "ORA-20031": "Poți modifica doar fișele tale!",
            "ORA-20033": "Doar medicii pot șterge fișe!",
            "ORA-20034": "Poți șterge doar fișele tale!",
            "ORA-20041": "CNP există deja!",
            "ORA-20042": "Nu poți modifica pacienți!",
            "ORA-20043": "Pacient negăsit!",
            "ORA-20045": "Doar admin poate șterge pacienți!",
            "ORA-20046": "Pacientul are fișe medicale!",
            "ORA-20050": "Doar admin poate adăuga personal!",
            "ORA-20051": "CNP/username există deja!",
            "ORA-20055": "Doar admin poate șterge personal!",
            "ORA-20056": "Nu te poți șterge pe tine!",
            "ORA-20057": "Are fișe medicale create!",
            "ORA-01920": "User Oracle există deja!",
        }
        for code, txt in errors.items():
            if code in msg:
                console.print(f"[red]{txt}[/red]")
                return
        console.print(f"[red]{e}[/red]")

    # ===========================================
    # PACIENȚI
    # ===========================================

    def menu_pacienti(self):
        while True:
            self.header()
            console.print("\n[bold]Pacienți[/bold]\n")
            console.print("1. Vezi pacienți")
            console.print("2. Adaugă pacient")
            console.print("3. Modifică pacient")
            console.print("4. Șterge pacient")
            console.print("0. Înapoi")
            
            choice = Prompt.ask("\nSelectează", choices=["0", "1", "2", "3", "4"])
            
            if choice == "0":
                break
            elif choice == "1":
                self.view_pacienti()
            elif choice == "2":
                self.add_pacient()
            elif choice == "3":
                self.update_pacient()
            elif choice == "4":
                self.delete_pacient()

    def view_pacienti(self):
        self.header()
        console.print("\n[bold]Lista Pacienți[/bold]\n")
        try:
            rows = self.query("""
                SELECT id_pacient, nume, prenume, cnp_display, telefon, grupa_sanguina
                FROM TABLE(careconnect.get_pacienti())
            """)
            self.show_table(rows, ["ID", "Nume", "Prenume", "CNP", "Telefon", "Grupă"])
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def add_pacient(self):
        self.header()
        console.print("\n[bold]Adaugă Pacient[/bold]\n")
        try:
            nume = Prompt.ask("Nume")
            prenume = Prompt.ask("Prenume")
            cnp = Prompt.ask("CNP (13 cifre)")
            data_nasterii = Prompt.ask("Data nașterii (YYYY-MM-DD)")
            sex = Prompt.ask("Sex (M/F)", choices=["M", "F"])
            telefon = Prompt.ask("Telefon")
            adresa = Prompt.ask("Adresă")
            email = Prompt.ask("Email", default="")
            grupa = Prompt.ask("Grupa sanguină (A+/A-/B+/B-/AB+/AB-/O+/O-)", default="")

            with self.conn.cursor() as c:
                id_out = c.var(oracledb.NUMBER)
                c.execute("""
                    BEGIN careconnect.add_pacient(
                        p_nume => :nume, p_prenume => :prenume, p_cnp => :cnp,
                        p_data_nasterii => TO_DATE(:data_n, 'YYYY-MM-DD'), p_sex => :sex,
                        p_telefon => :tel, p_adresa => :adresa,
                        p_email => :email, p_grupa_sanguina => :grupa,
                        p_id_pacient => :id_out
                    ); END;
                """, {"nume": nume, "prenume": prenume, "cnp": cnp,
                      "data_n": data_nasterii, "sex": sex, "tel": telefon, "adresa": adresa,
                      "email": email or None, "grupa": grupa or None, "id_out": id_out})
                console.print(f"\n[green]Pacient #{int(id_out.getvalue())} adăugat![/green]")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def update_pacient(self):
        self.header()
        console.print("\n[bold]Modifică Pacient[/bold]\n")
        if self.grad < 2:
            console.print("[red]Acces interzis![/red]")
            self.wait()
            return
        try:
            self.view_pacienti_list()
            pid = IntPrompt.ask("\nID pacient")
            console.print("[dim]Lasă gol pentru a păstra valoarea curentă[/dim]\n")
            
            nume = Prompt.ask("Nume nou", default="")
            prenume = Prompt.ask("Prenume nou", default="")
            telefon = Prompt.ask("Telefon nou", default="")
            
            self.execute("""
                BEGIN careconnect.update_pacient(
                    p_id_pacient => :id, p_nume => :nume, p_prenume => :prenume, p_telefon => :tel
                ); END;
            """, {"id": pid, "nume": nume or None, "prenume": prenume or None, "tel": telefon or None})
            console.print(f"\n[green]Pacient #{pid} modificat![/green]")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def delete_pacient(self):
        self.header()
        console.print("\n[bold]Șterge Pacient[/bold]\n")
        if self.grad < 4:
            console.print("[red]Doar admin poate șterge pacienți![/red]")
            self.wait()
            return
        try:
            self.view_pacienti_list()
            pid = IntPrompt.ask("\nID pacient")
            if Confirm.ask(f"Ștergi pacientul #{pid}?"):
                self.execute("BEGIN careconnect.delete_pacient(:id); END;", {"id": pid})
                console.print(f"\n[green]Pacient #{pid} șters![/green]")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def view_pacienti_list(self):
        rows = self.query("SELECT id_pacient, nume, prenume FROM TABLE(careconnect.get_pacienti())")
        self.show_table(rows, ["ID", "Nume", "Prenume"])

    # ===========================================
    # FIȘE MEDICALE
    # ===========================================

    def menu_fise(self):
        while True:
            self.header()
            console.print("\n[bold]Fișe Medicale[/bold]\n")
            console.print("1. Vezi fișe")
            console.print("2. Adaugă fișă")
            console.print("3. Modifică fișă")
            console.print("4. Șterge fișă")
            console.print("0. Înapoi")
            
            choice = Prompt.ask("\nSelectează", choices=["0", "1", "2", "3", "4"])
            
            if choice == "0":
                break
            elif choice == "1":
                self.view_fise()
            elif choice == "2":
                self.add_fisa()
            elif choice == "3":
                self.update_fisa()
            elif choice == "4":
                self.delete_fisa()

    def view_fise(self):
        self.header()
        console.print("\n[bold]Fișe Medicale[/bold]\n")
        try:
            rows = self.query("""
                SELECT id_fisa, pacient_nume, medic_nume, diagnostic, nivel_confidentialitate
                FROM TABLE(careconnect.get_fise_medicale())
            """)
            self.show_table(rows, ["ID", "Pacient", "Medic", "Diagnostic", "Nivel"])
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def add_fisa(self):
        self.header()
        console.print("\n[bold]Adaugă Fișă Medicală[/bold]\n")
        if self.grad < 3:
            console.print("[red]Doar medicii pot adăuga fișe![/red]")
            self.wait()
            return
        try:
            self.view_pacienti_list()
            pid = IntPrompt.ask("\nID pacient")
            diagnostic = Prompt.ask("Diagnostic")
            tratament = Prompt.ask("Tratament", default="")
            nivel = IntPrompt.ask("Nivel confidențialitate (1-3)", default=1)

            with self.conn.cursor() as c:
                id_out = c.var(oracledb.NUMBER)
                c.execute("""
                    BEGIN careconnect.add_fisa_medicala(
                        p_id_pacient => :pid, p_diagnostic => :diag, p_tratament => :trat,
                        p_nivel_confidentialitate => :nivel, p_id_fisa => :id_out
                    ); END;
                """, {"pid": pid, "diag": diagnostic, "trat": tratament or None,
                      "nivel": nivel, "id_out": id_out})
                console.print(f"\n[green]Fișă #{int(id_out.getvalue())} adăugată![/green]")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def update_fisa(self):
        self.header()
        console.print("\n[bold]Modifică Fișă[/bold]\n")
        if self.grad < 3:
            console.print("[red]Doar medicii pot modifica fișe![/red]")
            self.wait()
            return
        try:
            self.view_fise_list()
            fid = IntPrompt.ask("\nID fișă")
            console.print("[dim]Lasă gol pentru a păstra valoarea curentă[/dim]\n")
            
            diagnostic = Prompt.ask("Diagnostic nou", default="")
            tratament = Prompt.ask("Tratament nou", default="")
            
            self.execute("""
                BEGIN careconnect.update_fisa_medicala(
                    p_id_fisa => :id, p_diagnostic => :diag, p_tratament => :trat
                ); END;
            """, {"id": fid, "diag": diagnostic or None, "trat": tratament or None})
            console.print(f"\n[green]Fișă #{fid} modificată![/green]")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def delete_fisa(self):
        self.header()
        console.print("\n[bold]Șterge Fișă[/bold]\n")
        if self.grad < 3:
            console.print("[red]Doar medicii pot șterge fișe![/red]")
            self.wait()
            return
        try:
            self.view_fise_list()
            fid = IntPrompt.ask("\nID fișă")
            if Confirm.ask(f"Ștergi fișa #{fid}?"):
                self.execute("BEGIN careconnect.delete_fisa_medicala(:id); END;", {"id": fid})
                console.print(f"\n[green]Fișă #{fid} ștearsă![/green]")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def view_fise_list(self):
        rows = self.query("SELECT id_fisa, pacient_nume, diagnostic FROM TABLE(careconnect.get_fise_medicale())")
        self.show_table(rows, ["ID", "Pacient", "Diagnostic"])

    # ===========================================
    # PERSONAL
    # ===========================================

    def menu_personal(self):
        while True:
            self.header()
            console.print("\n[bold]Personal Medical[/bold]\n")
            console.print("1. Vezi personal")
            console.print("2. Adaugă personal")
            console.print("3. Modifică personal")
            console.print("4. Șterge personal")
            console.print("0. Înapoi")
            
            choice = Prompt.ask("\nSelectează", choices=["0", "1", "2", "3", "4"])
            
            if choice == "0":
                break
            elif choice == "1":
                self.view_personal()
            elif choice == "2":
                self.add_personal()
            elif choice == "3":
                self.update_personal()
            elif choice == "4":
                self.delete_personal()

    def view_personal(self):
        self.header()
        console.print("\n[bold]Personal Medical[/bold]\n")
        try:
            rows = self.query("""
                SELECT id_personal, nume, prenume, rol, grad_acces, nume_departament
                FROM TABLE(careconnect.get_personal())
            """)
            self.show_table(rows, ["ID", "Nume", "Prenume", "Rol", "Grad", "Departament"])
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def add_personal(self):
        self.header()
        console.print("\n[bold]Adaugă Personal[/bold]\n")
        if self.grad < 4:
            console.print("[red]Doar admin poate adăuga personal![/red]")
            self.wait()
            return
        try:
            nume = Prompt.ask("Nume")
            prenume = Prompt.ask("Prenume")
            cnp = Prompt.ask("CNP")
            email = Prompt.ask("Email")
            telefon = Prompt.ask("Telefon")
            rol = Prompt.ask("Rol (MEDIC/ASISTENT/RECEPȚIE/ADMIN)")
            grad = IntPrompt.ask("Grad acces (1-4)")
            
            console.print("\n[bold]Credențiale Oracle:[/bold]")
            username = Prompt.ask("Username")
            password = Prompt.ask("Parolă (min 8 caractere)", password=True)
            password2 = Prompt.ask("Confirmă parola", password=True)
            
            if password != password2:
                console.print("[red]Parolele nu coincid![/red]")
                self.wait()
                return
            if len(password) < 8:
                console.print("[red]Parola prea scurtă![/red]")
                self.wait()
                return

            with self.conn.cursor() as c:
                id_out = c.var(oracledb.NUMBER)
                c.execute("""
                    BEGIN careconnect.add_personal(
                        p_nume => :nume, p_prenume => :prenume, p_cnp => :cnp,
                        p_rol => :rol, p_grad_acces => :grad,
                        p_telefon => :telefon, p_email => :email,
                        p_username_db => :user, p_password => :pwd,
                        p_id_personal => :id_out
                    ); END;
                """, {"nume": nume, "prenume": prenume, "cnp": cnp,
                      "email": email, "telefon": telefon,
                      "rol": rol, "grad": grad, "user": username, "pwd": password,
                      "id_out": id_out})
                console.print(f"\n[green]Personal #{int(id_out.getvalue())} + user Oracle '{username}' create![/green]")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def update_personal(self):
        self.header()
        console.print("\n[bold]Modifică Personal[/bold]\n")
        if self.grad < 4:
            console.print("[red]Doar admin poate modifica personal![/red]")
            self.wait()
            return
        try:
            self.view_personal_list()
            pid = IntPrompt.ask("\nID personal")
            console.print("[dim]Lasă gol pentru a păstra valoarea curentă[/dim]\n")
            
            nume = Prompt.ask("Nume nou", default="")
            prenume = Prompt.ask("Prenume nou", default="")
            rol = Prompt.ask("Rol nou", default="")
            
            self.execute("""
                BEGIN careconnect.update_personal(
                    p_id_personal => :id, p_nume => :nume, p_prenume => :prenume, p_rol => :rol
                ); END;
            """, {"id": pid, "nume": nume or None, "prenume": prenume or None, "rol": rol or None})
            console.print(f"\n[green]Personal #{pid} modificat![/green]")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def delete_personal(self):
        self.header()
        console.print("\n[bold]Șterge Personal[/bold]\n")
        if self.grad < 4:
            console.print("[red]Doar admin poate șterge personal![/red]")
            self.wait()
            return
        try:
            self.view_personal_list()
            pid = IntPrompt.ask("\nID personal")
            if Confirm.ask(f"Ștergi personalul #{pid}?"):
                self.execute("BEGIN careconnect.delete_personal(:id); END;", {"id": pid})
                console.print(f"\n[green]Personal #{pid} șters![/green]")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    def view_personal_list(self):
        rows = self.query("SELECT id_personal, nume, prenume, rol FROM TABLE(careconnect.get_personal())")
        self.show_table(rows, ["ID", "Nume", "Prenume", "Rol"])

    # ===========================================
    # DECRIPTARE CNP
    # ===========================================

    def decrypt_cnp(self):
        self.header()
        console.print("\n[bold]Decriptare CNP[/bold]\n")
        if self.grad < 3:
            console.print("[red]Doar medicii pot decripta CNP![/red]")
            self.wait()
            return
        try:
            self.view_pacienti_list()
            pid = IntPrompt.ask("\nID pacient")
            
            info = self.query("SELECT careconnect.get_pacient_info(:id) FROM dual", {"id": pid})[0][0]
            if not info:
                console.print("[red]Pacient negăsit![/red]")
            else:
                cnp = self.query("SELECT careconnect.get_pacient_cnp_decriptat(:id) FROM dual", {"id": pid})[0][0]
                console.print(f"\n[green]{info}:[/green]")
                console.print(Panel(f"[bold yellow]{cnp}[/bold yellow]", title="CNP decriptat"))
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    # ===========================================
    # AUDIT
    # ===========================================

    def view_audit(self):
        self.header()
        console.print("\n[bold]Audit Log[/bold]\n")
        if self.grad < 4:
            console.print("[red]Doar admin poate vedea audit![/red]")
            self.wait()
            return
        try:
            rows = self.query("""
                SELECT audit_type, username, action_type, table_name, action_timestamp
                FROM TABLE(careconnect.get_audit_log(20))
            """)
            self.show_table(rows, ["Tip", "User", "Acțiune", "Tabel", "Timestamp"])
            
            stats = self.query("SELECT audit_type, total_count FROM TABLE(careconnect.get_audit_stats())")
            if stats:
                console.print("\n[bold]Statistici:[/bold]")
                for s in stats:
                    console.print(f"  {s[0]}: {s[1]}")
        except oracledb.Error as e:
            self.error(e)
        self.wait()

    # ===========================================
    # MAIN
    # ===========================================

    def run(self):
        while True:
            # Login
            if not self.conn:
                console.clear()
                console.print(Panel("[bold cyan]CareConnect[/bold cyan]\n[dim]Autentificare Oracle[/dim]", box=box.DOUBLE))
                user = Prompt.ask("\nUsername")
                if not user:
                    continue
                pwd = Prompt.ask("Password", password=True)
                if not self.connect(user, pwd):
                    self.wait()
                    continue

            # Meniu principal
            self.header()
            console.print("\n[bold]Meniu Principal[/bold]\n")
            console.print("1. Pacienți")
            console.print("2. Fișe Medicale")
            console.print("3. Personal Medical")
            console.print("4. Decriptare CNP")
            console.print("5. Audit Log")
            console.print("6. Schimbă utilizator")
            console.print("0. Ieșire")
            
            choice = Prompt.ask("\nSelectează", choices=["0", "1", "2", "3", "4", "5", "6"])
            
            if choice == "0":
                self.disconnect()
                console.print("[dim]La revedere![/dim]")
                break
            elif choice == "1":
                self.menu_pacienti()
            elif choice == "2":
                self.menu_fise()
            elif choice == "3":
                self.menu_personal()
            elif choice == "4":
                self.decrypt_cnp()
            elif choice == "5":
                self.view_audit()
            elif choice == "6":
                self.disconnect()


if __name__ == "__main__":
    try:
        CareConnectCLI().run()
    except KeyboardInterrupt:
        console.print("\n[dim]Închis.[/dim]")
        sys.exit(0)
