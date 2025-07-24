Cryogenics is the study and application of materials and systems at extremely low temperatures, typically below 123 K. These conditions are common in fields such as aerospace, superconductivity, quantum technology, and biological preservation, where materials are cooled using substances like liquid nitrogen or helium. At such low temperatures, thermal behavior changes significantly, and the rate at which materials cool — as well as the amount of energy they lose during the process — becomes critical for design, safety, and operational planning.

This project aims to simulate the thermal response of various materials under cryogenic conditions. Specifically, it models how temperature decreases over time using Newton’s Law of Cooling and calculates the corresponding energy loss. The simulation also accounts for geometric effects on cooling behavior by adjusting for object shape (e.g., sphere, cube, plate), and supports staged ambient temperature drops to reflect multi-phase cooling environments.

The goal is to produce time-series data and visualizations that show:
1. How quickly each material cools,
2. How much energy is extracted during cooling,
3. How geometry affects the cooling rate,
4. And how staged temperature environments influence the overall process.

The project is implemented in Bash, using basic tools (bc, gnuplot) to generate output data and plots, offering a simple, transparent, and modular approach to simulating cryogenic cooling behavior.
