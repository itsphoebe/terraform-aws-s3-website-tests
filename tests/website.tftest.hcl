mock_provider "aws" {
  override_resource {
    target = aws_s3_object.error
    values = {
      etag = "41c9c4a40588e60157641374e9af805b"
    }
  }
  override_resource {
    target = aws_s3_object.index
    values = {
      etag = "25e66e29196ead50c4267ce3a1d71b13"
    }
  }
}

# Call the setup module to create a random bucket prefix
run "setup_tests" {
  module {
    source = "./tests/setup"
  }
}

# Apply run block to create the bucket
run "create_bucket" {
  variables {
    bucket_name = "${run.setup_tests.bucket_prefix}-aws-s3-website-test"
  }

  # Check that the bucket name is correct
  assert {
    condition     = aws_s3_bucket.s3_bucket.bucket == "${run.setup_tests.bucket_prefix}-aws-s3-website-test"
    error_message = "Invalid bucket name"
  }

  # Check index.html hash matches
  assert {
    condition     = aws_s3_object.index.etag == filemd5("./www/index.html")
    error_message = "Invalid eTag for index.html"
  }

  # Check error.html hash matches
  assert {
    condition     = aws_s3_object.error.etag == filemd5("./www/error.html")
    error_message = "Invalid eTag for error.html"
  }
}

# run "website_is_running" {
#   command = plan

#   module {
#     source = "./tests/final"
#   }

#   variables {
#     endpoint = run.create_bucket.website_endpoint
#   }

#   assert {
#     condition = data.http.index.status_code == 200
#     error_message = "Webiste responded with HTTP status ${data.http.index.status_code}"
#   }
# }

# Note aws_instance and aws_db_instance are overridden here!
run "check_backend_api" {
  assert {
    condition = aws_instance.backend_api.tags.Name == "backend"
    error_message = "Invalid name tag"
  }

  assert {
    condition = aws_db_instance.backend_api.username == "foo"
    error_message = "Invalid database name"
  }
}

run "check_db_engine" {
  command = plan
  
  assert {
    condition = aws_db_instance.backend_api.engine == "mysql"
    error_message = "Invalid database engine"
  }
}