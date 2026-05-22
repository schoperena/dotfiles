def solicitar_nit():
    while True:
        nit = input("Ingrese el NIT (solo números, sin DV, 1 a 15 dígitos): ").strip()
        if nit.isdigit() and 1 <= len(nit) <= 15:
            return nit
        else:
            print("⚠️ El NIT debe tener entre 1 y 15 dígitos numéricos.")

def calcular_dv(nit):
    # Pesos oficiales de la DIAN (hasta 15 posiciones)
    pesos_dian = [71, 67, 59, 53, 47, 43, 41, 37, 29, 23, 19, 17, 13, 7, 3]
    
    # Tomar los pesos según la longitud del NIT (de derecha a izquierda)
    pesos = pesos_dian[-len(nit):]
    
    suma = sum(int(digito) * peso for digito, peso in zip(nit, pesos))
    residuo = suma % 11

    return residuo if residuo < 2 else 11 - residuo

def main():
    nit = solicitar_nit()
    dv = calcular_dv(nit)
    print(f"✅ El dígito de verificación para el NIT {nit} es: {dv}")

if __name__ == "__main__":
    main()
