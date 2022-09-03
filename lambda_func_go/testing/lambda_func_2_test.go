package main

import (
	"io"
	"net/http"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	v4 "github.com/aws/aws-sdk-go/aws/signer/v4"
)

func epochTime() time.Time { return time.Unix(0, 0) }

func Test_signing_request(t *testing.T) {
	req, body := buildRequest("execute-api", "us-east-1", "{}")

	signer := buildSigner()
	signer.Presign(req, body, "execute-api", "us-east-1", 300*time.Second, epochTime())

	expectedDate := "19700101T000000Z"
	expectedHeaders := "content-length;content-type;host;x-amz-meta-other-header;x-amz-meta-other-header_with_underscore"
	expectedSig := "9e12ae966de47bb6e93f6d487d6bc20fd230be98e0c6f6da4db6ca84d2ba2b64" //new
	expectedCred := "AKID/19700101/us-east-1/execute-api/aws4_request"
	expectedTarget := "prefix.Operation"

	q := req.URL.Query()
	if e, a := expectedSig, q.Get("X-Amz-Signature"); e != a {
		t.Errorf("expect %v, got %v", e, a)
	}
	if e, a := expectedCred, q.Get("X-Amz-Credential"); e != a {
		t.Errorf("expect %v, got %v", e, a)
	}
	if e, a := expectedHeaders, q.Get("X-Amz-SignedHeaders"); e != a {
		t.Errorf("expect %v, got %v", e, a)
	}
	if e, a := expectedDate, q.Get("X-Amz-Date"); e != a {
		t.Errorf("expect %v, got %v", e, a)
	}
	if a := q.Get("X-Amz-Meta-Other-Header"); len(a) != 0 {
		t.Errorf("expect %v to be empty", a)
	}
	if e, a := expectedTarget, q.Get("X-Amz-Target"); e != a {
		t.Errorf("expect %v, got %v", e, a)
	}
}

func buildRequest(serviceName, region, body string) (*http.Request, io.ReadSeeker) {
	reader := strings.NewReader(body)
	return buildRequestWithBodyReader(serviceName, region, reader)
}

func buildRequestWithBodyReader(serviceName, region string, body io.Reader) (*http.Request, io.ReadSeeker) {
	var bodyLen int

	type lenner interface {
		Len() int
	}
	if lr, ok := body.(lenner); ok {
		bodyLen = lr.Len()
	}

	endpoint := "https://" + serviceName + "." + region + ".amazonaws.com"
	req, _ := http.NewRequest("POST", endpoint, body)
	req.URL.Opaque = "//example.org/bucket/key-._~,!@#$%^&*()"
	req.Header.Set("X-Amz-Target", "prefix.Operation")
	req.Header.Set("Content-Type", "application/x-amz-json-1.0")

	if bodyLen > 0 {
		req.Header.Set("Content-Length", strconv.Itoa(bodyLen))
	}

	req.Header.Set("X-Amz-Meta-Other-Header", "some-value=!@#$%^&* (+)")
	req.Header.Add("X-Amz-Meta-Other-Header_With_Underscore", "some-value=!@#$%^&* (+)")
	req.Header.Add("X-amz-Meta-Other-Header_With_Underscore", "some-value=!@#$%^&* (+)")

	var seeker io.ReadSeeker
	if sr, ok := body.(io.ReadSeeker); ok {
		seeker = sr
	} else {
		seeker = aws.ReadSeekCloser(body)
	}

	return req, seeker
}

func buildSigner() v4.Signer {
	return v4.Signer{
		Credentials: credentials.NewStaticCredentials("AKID", "SECRET", "SESSION"),
	}
}
