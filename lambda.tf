
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.root}/build/lambda_function_payload.zip"

  source {
    content = <<-EOF
      exports.handler = async (event) => {
        return {
          statusCode: 200,
          body: JSON.stringify({ message: "Hello from Lambda" }),
        };
      };
    EOF
    filename = "index.js"
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "lambda_exec_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "example" {
  function_name    = "example_lambda_function"
  filename         = data.archive_file.lambda_zip.output_path
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

output "lambda_function_name" {
  value = aws_lambda_function.example.function_name
}
