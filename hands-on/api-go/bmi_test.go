package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func f(v float64) *float64 { return &v }

func TestClassify(t *testing.T) {
	cases := map[float64]string{
		15.9:  "Magreza grave",
		18.4:  "Abaixo do peso",
		22.86: "Peso normal",
		27:    "Sobrepeso",
		32:    "Obesidade grau I",
		37:    "Obesidade grau II",
		40:    "Obesidade grau III",
	}
	for bmi, want := range cases {
		if got := Classify(bmi); got != want {
			t.Errorf("Classify(%v) = %q, want %q", bmi, got, want)
		}
	}
}

func TestCalculate(t *testing.T) {
	got, err := Calculate(BmiRequest{Weight: f(70), Height: f(1.75)})
	if err != nil {
		t.Fatal(err)
	}
	if got.Bmi != 22.86 || got.Classification != "Peso normal" {
		t.Errorf("got %+v", got)
	}
}

func TestValidate(t *testing.T) {
	invalid := []BmiRequest{
		{},
		{Weight: f(-1), Height: f(1.75)},
		{Weight: f(501), Height: f(1.75)},
		{Weight: f(70), Height: f(0.4)},
		{Weight: f(70), Height: f(3.1)},
	}
	for _, req := range invalid {
		if len(req.Validate()) == 0 {
			t.Errorf("expected validation error for %+v", req)
		}
	}
}

func TestHandlers(t *testing.T) {
	srv := httptest.NewServer(newRouter())
	defer srv.Close()

	resp, err := http.Post(srv.URL+"/bmi/calculate", "application/json", strings.NewReader(`{"weight":70,"height":1.75}`))
	if err != nil {
		t.Fatal(err)
	}
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("status = %d, want 201", resp.StatusCode)
	}
	var result BmiResult
	_ = json.NewDecoder(resp.Body).Decode(&result)
	if result.Bmi != 22.86 {
		t.Errorf("bmi = %v", result.Bmi)
	}

	resp, _ = http.Post(srv.URL+"/bmi/calculate", "application/json", strings.NewReader(`{"weight":"abc"}`))
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("invalid body status = %d, want 400", resp.StatusCode)
	}

	if code := runHealthcheck(srv.URL + "/health"); code != 0 {
		t.Errorf("healthcheck exit = %d, want 0", code)
	}
}
