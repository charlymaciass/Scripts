import tkinter as tk
from datetime import datetime, timedelta

def convert_time():
    """Converts the time and displays the results in the output box."""

    ist_time = cst_entry.get()
    try:
        ist_datetime = datetime.strptime(ist_time, "%H:%M:%S")

        est_datetime = ist_datetime - timedelta(hours=9.5)
        cet_datetime = ist_datetime - timedelta(hours=3.5)

        output_text.delete("1.0", tk.END)  # Clear previous output
        output_text.insert(tk.END, f"{est_datetime.strftime('%H:%M:%S')} EST\n")
        output_text.insert(tk.END, f"{cet_datetime.strftime('%H:%M:%S')} CET")

    except ValueError:
        output_text.delete("1.0", tk.END)
        output_text.insert(tk.END, "Invalid Time")

# Create the main window
window = tk.Tk()
window.title("IST to EST/CET Converter")

# Create the CST entry field
cst_label = tk.Label(window, text="IST Time:")
cst_label.grid(row=0, column=0)

cst_entry = tk.Entry(window)
cst_entry.grid(row=0, column=1)

# Create the output box
output_text = tk.Text(window, height=2, width=20)
output_text.grid(row=1, column=0, columnspan=2)

# Create the Convert button
convert_button = tk.Button(window, text="Convert", command=convert_time)
convert_button.grid(row=2, column=1)

# Start the main loop
window.mainloop()
