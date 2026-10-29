package main

import (
	"errors"
	"math"
)

// BmiRequest espelha o CalculateBmiDto do backend NestJS.
type BmiRequest struct {
	Weight *float64 `json:"weight"`
	Height *float64 `json:"height"`
}

// BmiResult espelha o BmiResultDto do backend NestJS.
type BmiResult struct {
	Bmi            float64 `json:"bmi"`
	Classification string  `json:"classification"`
	Weight         float64 `json:"weight"`
	Height         float64 `json:"height"`
}

// Validate aplica as mesmas regras do class-validator no NestJS.
func (r BmiRequest) Validate() []string {
	var errs []string
	switch {
	case r.Weight == nil:
		errs = append(errs, "weight must be a number")
	case *r.Weight <= 0:
		errs = append(errs, "weight must be a positive number")
	case *r.Weight > 500:
		errs = append(errs, "weight must not be greater than 500")
	}
	switch {
	case r.Height == nil:
		errs = append(errs, "height must be a number")
	case *r.Height <= 0:
		errs = append(errs, "height must be a positive number")
	case *r.Height < 0.5:
		errs = append(errs, "height must not be less than 0.5")
	case *r.Height > 3:
		errs = append(errs, "height must not be greater than 3")
	}
	return errs
}

var errInvalid = errors.New("invalid input")

// Calculate calcula o IMC arredondado a 2 casas e sua classificação (OMS).
func Calculate(req BmiRequest) (BmiResult, error) {
	if len(req.Validate()) > 0 {
		return BmiResult{}, errInvalid
	}
	w, h := *req.Weight, *req.Height
	bmi := math.Round(w/(h*h)*100) / 100
	return BmiResult{Bmi: bmi, Classification: Classify(bmi), Weight: w, Height: h}, nil
}

// Classify retorna a classificação OMS para um valor de IMC.
func Classify(bmi float64) string {
	switch {
	case bmi < 16:
		return "Magreza grave"
	case bmi < 18.5:
		return "Abaixo do peso"
	case bmi < 25:
		return "Peso normal"
	case bmi < 30:
		return "Sobrepeso"
	case bmi < 35:
		return "Obesidade grau I"
	case bmi < 40:
		return "Obesidade grau II"
	default:
		return "Obesidade grau III"
	}
}
